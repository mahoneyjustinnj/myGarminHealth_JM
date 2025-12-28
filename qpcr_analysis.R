# qPCR Data Analysis in R
# This script provides functions for analyzing quantitative PCR data
# including delta-delta Ct calculations, statistics, and visualizations

library(ggplot2)
library(dplyr)
library(tidyr)

#' Calculate Delta Ct values
#'
#' @param ct_data Data frame with Ct values (genes x samples)
#' @param reference_genes Vector of reference gene names
#' @return Data frame with delta Ct values
calculate_delta_ct <- function(ct_data, reference_genes) {
  
  # Calculate mean Ct of reference genes
  ref_ct <- ct_data[reference_genes, , drop = FALSE]
  mean_ref_ct <- colMeans(ref_ct, na.rm = TRUE)
  
  # Get target genes
  target_genes <- setdiff(rownames(ct_data), reference_genes)
  target_data <- ct_data[target_genes, , drop = FALSE]
  
  # Calculate delta Ct
  delta_ct <- sweep(target_data, 2, mean_ref_ct, FUN = "-")
  
  return(delta_ct)
}


#' Calculate Delta-Delta Ct and Fold Change
#'
#' @param ct_data Data frame with Ct values (genes x samples)
#' @param reference_genes Vector of reference gene names
#' @param control_samples Vector of control sample names
#' @param treatment_samples Vector of treatment sample names (optional)
#' @return Data frame with ddCt and fold change results
calculate_delta_delta_ct <- function(ct_data, reference_genes, control_samples, 
                                     treatment_samples = NULL) {
  
  # Calculate delta Ct
  delta_ct <- calculate_delta_ct(ct_data, reference_genes)
  
  # Identify treatment samples if not provided
  if (is.null(treatment_samples)) {
    treatment_samples <- setdiff(colnames(delta_ct), control_samples)
  }
  
  # Calculate mean delta Ct for control group
  control_mean_dct <- rowMeans(delta_ct[, control_samples, drop = FALSE], na.rm = TRUE)
  
  # Calculate delta-delta Ct
  delta_delta_ct <- sweep(delta_ct, 1, control_mean_dct, FUN = "-")
  
  # Calculate fold change (2^-ddCt)
  fold_change <- 2^(-delta_delta_ct)
  
  # Create results data frame
  results <- data.frame(
    gene = rownames(delta_ct),
    control_mean_dCt = control_mean_dct,
    row.names = rownames(delta_ct)
  )
  
  # Add treatment results
  treatment_fc <- fold_change[, treatment_samples, drop = FALSE]
  results$treatment_mean_fold_change <- rowMeans(treatment_fc, na.rm = TRUE)
  results$treatment_sem_fold_change <- apply(treatment_fc, 1, function(x) {
    sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))
  })
  
  return(results)
}


#' Perform t-test on qPCR data
#'
#' @param ct_data Data frame with Ct values
#' @param reference_genes Vector of reference gene names
#' @param control_samples Vector of control sample names
#' @param treatment_samples Vector of treatment sample names
#' @return Data frame with statistical test results
qpcr_ttest <- function(ct_data, reference_genes, control_samples, treatment_samples) {
  
  # Calculate delta Ct
  delta_ct <- calculate_delta_ct(ct_data, reference_genes)
  
  # Perform t-test for each gene
  results_list <- lapply(rownames(delta_ct), function(gene) {
    control_dct <- as.numeric(delta_ct[gene, control_samples])
    treatment_dct <- as.numeric(delta_ct[gene, treatment_samples])
    
    # Remove NA values
    control_dct <- control_dct[!is.na(control_dct)]
    treatment_dct <- treatment_dct[!is.na(treatment_dct)]
    
    # Perform t-test
    test_result <- t.test(treatment_dct, control_dct)
    
    # Calculate fold change
    fc <- 2^(-(mean(treatment_dct) - mean(control_dct)))
    
    data.frame(
      gene = gene,
      control_mean_dCt = mean(control_dct),
      treatment_mean_dCt = mean(treatment_dct),
      fold_change = fc,
      t_statistic = test_result$statistic,
      p_value = test_result$p.value
    )
  })
  
  results_df <- do.call(rbind, results_list)
  
  # FDR correction
  results_df$p_adjusted <- p.adjust(results_df$p_value, method = "fdr")
  
  return(results_df)
}


#' Perform ANOVA on qPCR data
#'
#' @param ct_data Data frame with Ct values
#' @param reference_genes Vector of reference gene names
#' @param sample_groups Named list of sample groups
#' @return Data frame with ANOVA results
qpcr_anova <- function(ct_data, reference_genes, sample_groups) {
  
  # Calculate delta Ct
  delta_ct <- calculate_delta_ct(ct_data, reference_genes)
  
  # Perform ANOVA for each gene
  results_list <- lapply(rownames(delta_ct), function(gene) {
    
    # Prepare data for ANOVA
    gene_data <- as.numeric(delta_ct[gene, ])
    group_labels <- rep(names(sample_groups), sapply(sample_groups, length))
    
    # Create data frame
    anova_df <- data.frame(
      dCt = gene_data,
      group = factor(group_labels)
    )
    
    # Perform ANOVA
    anova_result <- aov(dCt ~ group, data = anova_df)
    anova_summary <- summary(anova_result)
    
    data.frame(
      gene = gene,
      f_statistic = anova_summary[[1]]$`F value`[1],
      p_value = anova_summary[[1]]$`Pr(>F)`[1]
    )
  })
  
  results_df <- do.call(rbind, results_list)
  
  # FDR correction
  results_df$p_adjusted <- p.adjust(results_df$p_value, method = "fdr")
  
  return(results_df)
}


#' Plot qPCR fold change bar chart
#'
#' @param fold_changes Named vector or data frame with fold changes
#' @param errors Optional vector with error values
#' @param p_values Optional vector with p-values
#' @param title Plot title
#' @param p_threshold P-value threshold for significance stars
#' @return ggplot object
plot_qpcr_bar <- function(fold_changes, errors = NULL, p_values = NULL,
                         title = "qPCR Fold Change", p_threshold = 0.05) {
  
  # Convert to data frame if needed
  if (is.vector(fold_changes)) {
    df <- data.frame(
      gene = names(fold_changes),
      fold_change = as.numeric(fold_changes)
    )
  } else {
    df <- fold_changes
  }
  
  # Add errors if provided
  if (!is.null(errors)) {
    df$error <- errors
  }
  
  # Add p-values if provided
  if (!is.null(p_values)) {
    df$p_value <- p_values
    df$significant <- ifelse(df$p_value < p_threshold, "*", "")
  }
  
  # Create plot
  p <- ggplot(df, aes(x = gene, y = fold_change)) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7, color = "black") +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red", alpha = 0.5) +
    labs(
      title = title,
      x = "Gene",
      y = "Fold Change (2^-ddCt)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  # Add error bars if available
  if (!is.null(errors)) {
    p <- p + geom_errorbar(
      aes(ymin = fold_change - error, ymax = fold_change + error),
      width = 0.2,
      color = "black"
    )
  }
  
  # Add significance stars if available
  if (!is.null(p_values)) {
    df$y_pos <- df$fold_change + ifelse(!is.null(errors), df$error, 0) + 0.1
    p <- p + geom_text(
      data = df[df$significant == "*", ],
      aes(x = gene, y = y_pos, label = significant),
      size = 6,
      vjust = 0
    )
  }
  
  return(p)
}


#' Plot Ct values boxplot
#'
#' @param ct_data Data frame with Ct values
#' @param gene Gene name to plot
#' @param sample_groups Named list of sample groups
#' @param title Plot title (optional)
#' @return ggplot object
plot_ct_values <- function(ct_data, gene, sample_groups = NULL, title = NULL) {
  
  # Get gene data
  gene_data <- as.numeric(ct_data[gene, ])
  sample_names <- colnames(ct_data)
  
  # Create data frame
  df <- data.frame(
    sample = sample_names,
    ct_value = gene_data
  )
  
  # Add groups if provided
  if (!is.null(sample_groups)) {
    group_labels <- rep(names(sample_groups), sapply(sample_groups, length))
    df$group <- factor(group_labels)
    
    p <- ggplot(df, aes(x = group, y = ct_value, fill = group)) +
      geom_boxplot(alpha = 0.7) +
      geom_jitter(width = 0.2, alpha = 0.5, size = 2) +
      labs(
        title = ifelse(is.null(title), paste("Ct Values -", gene), title),
        x = "Group",
        y = "Ct Value",
        fill = "Group"
      )
  } else {
    p <- ggplot(df, aes(x = sample, y = ct_value)) +
      geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
      labs(
        title = ifelse(is.null(title), paste("Ct Values -", gene), title),
        x = "Sample",
        y = "Ct Value"
      ) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  
  p <- p + theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
    )
  
  return(p)
}


#' Calculate amplification efficiency from standard curve
#'
#' @param ct_values Vector of Ct values
#' @param dilutions Vector of dilution factors
#' @param gene_name Gene name for plot title
#' @return List with efficiency, R-squared, and plot
calculate_efficiency <- function(ct_values, dilutions, gene_name = "Gene") {
  
  # Calculate log10 dilutions
  log_dilutions <- log10(dilutions)
  
  # Linear regression
  fit <- lm(ct_values ~ log_dilutions)
  
  # Extract parameters
  slope <- coef(fit)[2]
  intercept <- coef(fit)[1]
  r_squared <- summary(fit)$r.squared
  
  # Calculate efficiency: E = 10^(-1/slope) - 1
  efficiency <- (10^(-1/slope) - 1) * 100
  
  # Create plot
  df <- data.frame(
    log_dilution = log_dilutions,
    ct = ct_values
  )
  
  p <- ggplot(df, aes(x = log_dilution, y = ct)) +
    geom_point(size = 4, color = "blue", alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
    labs(
      title = sprintf("%s - Standard Curve\nEfficiency: %.1f%%, R² = %.4f",
                     gene_name, efficiency, r_squared),
      x = "Log10(Dilution)",
      y = "Ct Value"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 12, face = "bold")
    ) +
    annotate(
      "text",
      x = min(log_dilutions),
      y = max(ct_values),
      label = sprintf("y = %.2fx + %.2f", slope, intercept),
      hjust = 0,
      vjust = 1
    )
  
  return(list(
    efficiency = efficiency,
    r_squared = r_squared,
    slope = slope,
    intercept = intercept,
    plot = p
  ))
}


#' Detect outliers in technical replicates
#'
#' @param ct_values Vector of Ct values
#' @param method Method for outlier detection ("iqr" or "zscore")
#' @param threshold Threshold value
#' @return Logical vector indicating outliers
detect_outliers <- function(ct_values, method = "iqr", threshold = 1.5) {
  
  if (method == "iqr") {
    Q1 <- quantile(ct_values, 0.25, na.rm = TRUE)
    Q3 <- quantile(ct_values, 0.75, na.rm = TRUE)
    IQR <- Q3 - Q1
    
    lower_bound <- Q1 - threshold * IQR
    upper_bound <- Q3 + threshold * IQR
    
    outliers <- ct_values < lower_bound | ct_values > upper_bound
    
  } else if (method == "zscore") {
    z_scores <- abs(scale(ct_values))
    outliers <- z_scores > threshold
  }
  
  return(outliers)
}


#' Calculate coefficient of variation for technical replicates
#'
#' @param ct_values Vector of Ct values
#' @return CV percentage
calculate_cv <- function(ct_values) {
  
  mean_ct <- mean(ct_values, na.rm = TRUE)
  sd_ct <- sd(ct_values, na.rm = TRUE)
  
  cv <- (sd_ct / mean_ct) * 100
  
  return(cv)
}


# Print available functions
cat("qPCR Analysis Functions Loaded:\n")
cat("- calculate_delta_ct()\n")
cat("- calculate_delta_delta_ct()\n")
cat("- qpcr_ttest()\n")
cat("- qpcr_anova()\n")
cat("- plot_qpcr_bar()\n")
cat("- plot_ct_values()\n")
cat("- calculate_efficiency()\n")
cat("- detect_outliers()\n")
cat("- calculate_cv()\n")
