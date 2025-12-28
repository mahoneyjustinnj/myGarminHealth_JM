# RNA-seq Data Analysis in R
# This script provides functions for RNA-seq analysis using popular R packages
# including DESeq2, edgeR, and visualization tools

library(DESeq2)
library(edgeR)
library(ggplot2)
library(pheatmap)
library(dplyr)
library(tidyr)

#' Perform DESeq2 Differential Expression Analysis
#'
#' @param count_matrix Count matrix (genes x samples)
#' @param sample_info Data frame with sample information (must include 'condition' column)
#' @param design_formula Design formula (default: ~condition)
#' @param alpha Significance threshold (default: 0.05)
#' @return DESeqDataSet object with results
perform_deseq2_analysis <- function(count_matrix, sample_info, 
                                   design_formula = ~condition, 
                                   alpha = 0.05) {
  
  # Create DESeq2 dataset
  dds <- DESeqDataSetFromMatrix(
    countData = count_matrix,
    colData = sample_info,
    design = design_formula
  )
  
  # Filter low count genes
  keep <- rowSums(counts(dds)) >= 10
  dds <- dds[keep, ]
  
  # Run DESeq2
  dds <- DESeq(dds)
  
  # Get results
  res <- results(dds, alpha = alpha)
  
  # Add gene symbols
  res$gene <- rownames(res)
  
  # Order by p-value
  res <- res[order(res$padj), ]
  
  return(list(dds = dds, results = res))
}


#' Perform edgeR Differential Expression Analysis
#'
#' @param count_matrix Count matrix (genes x samples)
#' @param group_vector Vector of group labels for samples
#' @param fdr FDR threshold (default: 0.05)
#' @return List containing DGEList and results
perform_edger_analysis <- function(count_matrix, group_vector, fdr = 0.05) {
  
  # Create DGEList object
  y <- DGEList(counts = count_matrix, group = group_vector)
  
  # Filter low count genes
  keep <- filterByExpr(y)
  y <- y[keep, , keep.lib.sizes = FALSE]
  
  # Normalize
  y <- calcNormFactors(y)
  
  # Estimate dispersion
  design <- model.matrix(~group_vector)
  y <- estimateDisp(y, design)
  
  # Fit GLM
  fit <- glmQLFit(y, design)
  qlf <- glmQLFTest(fit, coef = 2)
  
  # Get results
  results <- topTags(qlf, n = Inf, adjust.method = "BH")
  
  return(list(dge = y, results = results))
}


#' Normalize counts using TPM
#'
#' @param counts Count matrix
#' @param gene_lengths Named vector of gene lengths
#' @return TPM-normalized matrix
normalize_tpm <- function(counts, gene_lengths) {
  
  # Align gene lengths with count matrix
  gene_lengths <- gene_lengths[rownames(counts)]
  
  # Calculate RPK
  rpk <- counts / (gene_lengths / 1000)
  
  # Calculate scaling factor
  scaling_factor <- colSums(rpk) / 1e6
  
  # Calculate TPM
  tpm <- sweep(rpk, 2, scaling_factor, FUN = "/")
  
  return(tpm)
}


#' Create volcano plot
#'
#' @param results DESeq2 or edgeR results object
#' @param fc_threshold Fold change threshold (default: 2)
#' @param p_threshold P-value threshold (default: 0.05)
#' @param title Plot title
#' @return ggplot object
plot_volcano <- function(results, fc_threshold = 2, p_threshold = 0.05, 
                        title = "Volcano Plot") {
  
  # Convert to data frame if needed
  if (class(results)[1] == "DESeqResults") {
    df <- as.data.frame(results)
    df$log2FoldChange <- df$log2FoldChange
    df$padj <- df$padj
  } else if (class(results)[1] == "TopTags") {
    df <- results$table
    df$log2FoldChange <- df$logFC
    df$padj <- df$FDR
  } else {
    df <- as.data.frame(results)
  }
  
  # Remove NA values
  df <- df[!is.na(df$padj), ]
  
  # Add significance column
  df$significant <- ifelse(
    abs(df$log2FoldChange) >= log2(fc_threshold) & df$padj <= p_threshold,
    "Significant",
    "Not Significant"
  )
  
  # Create plot
  p <- ggplot(df, aes(x = log2FoldChange, y = -log10(padj), color = significant)) +
    geom_point(alpha = 0.5, size = 2) +
    scale_color_manual(values = c("Not Significant" = "gray", "Significant" = "red")) +
    geom_hline(yintercept = -log10(p_threshold), linetype = "dashed", color = "blue") +
    geom_vline(xintercept = c(-log2(fc_threshold), log2(fc_threshold)), 
               linetype = "dashed", color = "green") +
    labs(
      title = title,
      x = "Log2 Fold Change",
      y = "-Log10 Adjusted P-value",
      color = "Status"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      legend.position = "right"
    )
  
  return(p)
}


#' Create MA plot
#'
#' @param results DESeq2 results object
#' @param alpha Significance threshold
#' @return ggplot object
plot_ma <- function(results, alpha = 0.05) {
  
  df <- as.data.frame(results)
  df <- df[!is.na(df$padj), ]
  df$significant <- ifelse(df$padj <= alpha, "Significant", "Not Significant")
  
  p <- ggplot(df, aes(x = baseMean, y = log2FoldChange, color = significant)) +
    geom_point(alpha = 0.5, size = 1) +
    scale_x_log10() +
    scale_color_manual(values = c("Not Significant" = "gray", "Significant" = "red")) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      title = "MA Plot",
      x = "Mean Expression (log10)",
      y = "Log2 Fold Change",
      color = "Status"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
    )
  
  return(p)
}


#' Create expression heatmap
#'
#' @param vsd Variance stabilized or rlog transformed data
#' @param top_genes Number of top genes to include
#' @param annotation_col Data frame with sample annotations
#' @return pheatmap object
plot_expression_heatmap <- function(vsd, top_genes = 50, annotation_col = NULL) {
  
  # Get top variable genes
  rv <- rowVars(assay(vsd))
  select <- order(rv, decreasing = TRUE)[seq_len(min(top_genes, length(rv)))]
  
  # Get data for selected genes
  mat <- assay(vsd)[select, ]
  
  # Z-score normalization
  mat <- t(scale(t(mat)))
  
  # Create heatmap
  pheatmap(
    mat,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = ifelse(top_genes <= 50, TRUE, FALSE),
    annotation_col = annotation_col,
    color = colorRampPalette(c("blue", "white", "red"))(100),
    breaks = seq(-2, 2, length.out = 101),
    main = paste("Top", top_genes, "Variable Genes"),
    fontsize = 10
  )
}


#' Perform PCA and create plot
#'
#' @param vsd Variance stabilized or rlog transformed data
#' @param intgroup Column name(s) from colData to use for grouping
#' @return ggplot object
plot_pca_analysis <- function(vsd, intgroup = "condition") {
  
  pcaData <- plotPCA(vsd, intgroup = intgroup, returnData = TRUE)
  percentVar <- round(100 * attr(pcaData, "percentVar"))
  
  p <- ggplot(pcaData, aes(x = PC1, y = PC2, color = !!sym(intgroup))) +
    geom_point(size = 4, alpha = 0.8) +
    labs(
      title = "PCA Plot",
      x = paste0("PC1: ", percentVar[1], "% variance"),
      y = paste0("PC2: ", percentVar[2], "% variance")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      legend.position = "right"
    )
  
  return(p)
}


#' Perform Gene Set Enrichment Analysis (GSEA)
#'
#' @param ranked_genes Named vector of genes with ranking metric
#' @param gene_sets List of gene sets
#' @return Enrichment results
perform_gsea <- function(ranked_genes, gene_sets) {
  
  # This is a placeholder - actual GSEA would require fgsea or similar
  # Install fgsea if needed: BiocManager::install("fgsea")
  
  if (!requireNamespace("fgsea", quietly = TRUE)) {
    message("fgsea package not installed. Install with: BiocManager::install('fgsea')")
    return(NULL)
  }
  
  library(fgsea)
  
  # Run GSEA
  fgseaRes <- fgsea(
    pathways = gene_sets,
    stats = ranked_genes,
    minSize = 15,
    maxSize = 500
  )
  
  # Order by p-value
  fgseaRes <- fgseaRes[order(fgseaRes$pval), ]
  
  return(fgseaRes)
}


#' Calculate QC metrics
#'
#' @param count_matrix Count matrix
#' @return Data frame with QC metrics
calculate_qc_metrics <- function(count_matrix) {
  
  qc_df <- data.frame(
    sample = colnames(count_matrix),
    total_reads = colSums(count_matrix),
    genes_detected = colSums(count_matrix > 0),
    median_expression = apply(count_matrix, 2, median),
    mean_expression = colMeans(count_matrix)
  )
  
  # Top 10 genes percentage
  top10_pct <- apply(count_matrix, 2, function(x) {
    sum(sort(x, decreasing = TRUE)[1:10]) / sum(x) * 100
  })
  qc_df$top10_genes_pct <- top10_pct
  
  return(qc_df)
}


#' Extract significant genes
#'
#' @param results DESeq2 results
#' @param padj_threshold Adjusted p-value threshold
#' @param fc_threshold Fold change threshold (linear scale)
#' @return Data frame of significant genes
get_significant_genes <- function(results, padj_threshold = 0.05, fc_threshold = 2) {
  
  sig <- results[
    !is.na(results$padj) & 
    results$padj < padj_threshold & 
    abs(results$log2FoldChange) >= log2(fc_threshold),
  ]
  
  sig <- as.data.frame(sig)
  sig <- sig[order(sig$padj), ]
  
  return(sig)
}


# Print available functions
cat("RNA-seq Analysis Functions Loaded:\n")
cat("- perform_deseq2_analysis()\n")
cat("- perform_edger_analysis()\n")
cat("- normalize_tpm()\n")
cat("- plot_volcano()\n")
cat("- plot_ma()\n")
cat("- plot_expression_heatmap()\n")
cat("- plot_pca_analysis()\n")
cat("- perform_gsea()\n")
cat("- calculate_qc_metrics()\n")
cat("- get_significant_genes()\n")
