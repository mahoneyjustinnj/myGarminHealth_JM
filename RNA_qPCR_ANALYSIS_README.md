# RNA-seq and qPCR Analysis Tools

This repository now includes comprehensive tools for analyzing RNA sequencing and quantitative PCR data.

## New Analysis Modules

### Python Modules

#### 1. RNA-seq Analysis (`rna_seq_analysis.py`)
Comprehensive RNA-seq data analysis toolkit including:

**Normalization Functions:**
- `calculate_tpm()` - Transcripts Per Million normalization
- `calculate_fpkm()` - Fragments Per Kilobase Million normalization
- `calculate_cpm()` - Counts Per Million normalization

**Data Filtering and QC:**
- `filter_low_expression()` - Remove low-expression genes
- `calculate_qc_metrics()` - Quality control metrics per sample

**Differential Expression:**
- `calculate_fold_change()` - Log2 fold change calculation
- `perform_ttest()` - Statistical testing with FDR correction

**Visualization:**
- `plot_volcano()` - Volcano plot for DE results
- `plot_heatmap()` - Expression heatmap
- `plot_pca()` - Principal component analysis

**Example Usage:**
```python
import pandas as pd
from rna_seq_analysis import *

# Load count data
counts = pd.read_csv('counts.csv', index_col=0)

# Normalize using TPM
gene_lengths = pd.read_csv('gene_lengths.csv', index_col=0)['length']
tpm = calculate_tpm(counts, gene_lengths)

# Filter low expression
filtered = filter_low_expression(counts, min_count=10, min_samples=2)

# Differential expression
treatment_samples = ['T1', 'T2', 'T3']
control_samples = ['C1', 'C2', 'C3']
results = perform_ttest(filtered[treatment_samples], filtered[control_samples])

# Calculate fold change
fc = calculate_fold_change(filtered[treatment_samples], filtered[control_samples])

# Visualize
fig = plot_volcano(fc, results['p_adjusted'])
fig.savefig('volcano_plot.png')
```

#### 2. qPCR Analysis (`qpcr_analysis.py`)
Complete qPCR data analysis toolkit including:

**Quantification:**
- `calculate_delta_ct()` - Delta Ct calculation
- `calculate_delta_delta_ct()` - Delta-delta Ct and fold change (2^-ddCt)
- `calculate_relative_expression()` - Relative expression quantification

**Statistical Analysis:**
- `qpcr_ttest()` - t-test for two groups
- `qpcr_anova()` - ANOVA for multiple groups

**Quality Control:**
- `detect_outliers()` - Outlier detection in replicates
- `calculate_technical_replicate_cv()` - Coefficient of variation

**Visualization:**
- `plot_qpcr_bar()` - Bar chart with error bars and significance
- `plot_ct_values()` - Ct value distribution
- `plot_amplification_efficiency()` - Standard curve and efficiency

**Example Usage:**
```python
import pandas as pd
from qpcr_analysis import *

# Load Ct data
ct_data = pd.read_csv('ct_values.csv', index_col=0)

# Define groups
reference_genes = ['GAPDH', 'ACTB']
control_samples = ['Ctrl_1', 'Ctrl_2', 'Ctrl_3']
treatment_samples = ['Treat_1', 'Treat_2', 'Treat_3']

# Calculate delta-delta Ct
results = calculate_delta_delta_ct(ct_data, reference_genes, 
                                   control_samples, treatment_samples)

# Statistical test
stats = qpcr_ttest(ct_data, reference_genes, control_samples, treatment_samples)

# Plot results
fig = plot_qpcr_bar(
    stats['fold_change'], 
    errors=results['treatment_sem_fold_change'],
    p_values=stats['p_adjusted']
)
fig.savefig('qpcr_results.png')

# Check amplification efficiency
efficiency_results = plot_amplification_efficiency(
    ct_values=[15, 18, 21, 24],
    dilutions=[1, 10, 100, 1000],
    gene_name='Target_Gene'
)
print(f"Efficiency: {efficiency_results[1]:.2f}%")
```

### R Scripts

#### 3. RNA-seq Analysis (`rna_seq_analysis.R`)
R-based RNA-seq analysis using popular Bioconductor packages:

**Differential Expression:**
- `perform_deseq2_analysis()` - DESeq2 wrapper
- `perform_edger_analysis()` - edgeR wrapper

**Normalization:**
- `normalize_tpm()` - TPM normalization

**Visualization:**
- `plot_volcano()` - Volcano plot
- `plot_ma()` - MA plot
- `plot_expression_heatmap()` - Expression heatmap
- `plot_pca_analysis()` - PCA plot

**Utilities:**
- `calculate_qc_metrics()` - Quality metrics
- `get_significant_genes()` - Extract significant results
- `perform_gsea()` - Gene set enrichment analysis (requires fgsea)

**Example Usage:**
```r
source('rna_seq_analysis.R')

# Load data
count_matrix <- read.csv('counts.csv', row.names=1)
sample_info <- data.frame(
  condition = c(rep('control', 3), rep('treatment', 3)),
  row.names = colnames(count_matrix)
)

# Run DESeq2
results <- perform_deseq2_analysis(count_matrix, sample_info)

# Visualize
volcano_plot <- plot_volcano(results$results)
print(volcano_plot)

# PCA
vsd <- vst(results$dds)
pca_plot <- plot_pca_analysis(vsd)
print(pca_plot)

# Get significant genes
sig_genes <- get_significant_genes(results$results, 
                                   padj_threshold=0.05, 
                                   fc_threshold=2)
```

#### 4. qPCR Analysis (`qpcr_analysis.R`)
R-based qPCR analysis with statistical testing:

**Quantification:**
- `calculate_delta_ct()` - Delta Ct
- `calculate_delta_delta_ct()` - Delta-delta Ct and fold change

**Statistics:**
- `qpcr_ttest()` - t-test
- `qpcr_anova()` - ANOVA

**Visualization:**
- `plot_qpcr_bar()` - Bar chart with significance
- `plot_ct_values()` - Ct value boxplot
- `calculate_efficiency()` - Standard curve and efficiency

**Quality Control:**
- `detect_outliers()` - Outlier detection
- `calculate_cv()` - Coefficient of variation

**Example Usage:**
```r
source('qpcr_analysis.R')

# Load data
ct_data <- read.csv('ct_values.csv', row.names=1)

# Define experimental setup
reference_genes <- c('GAPDH', 'ACTB')
control_samples <- c('Ctrl_1', 'Ctrl_2', 'Ctrl_3')
treatment_samples <- c('Treat_1', 'Treat_2', 'Treat_3')

# Calculate fold changes
results <- calculate_delta_delta_ct(ct_data, reference_genes, 
                                   control_samples, treatment_samples)

# Statistical test
stats <- qpcr_ttest(ct_data, reference_genes, 
                   control_samples, treatment_samples)

# Plot
bar_plot <- plot_qpcr_bar(stats$fold_change, 
                         errors=results$treatment_sem_fold_change,
                         p_values=stats$p_adjusted)
print(bar_plot)

# Check efficiency
eff_results <- calculate_efficiency(
  ct_values=c(15, 18, 21, 24),
  dilutions=c(1, 10, 100, 1000),
  gene_name='Target_Gene'
)
print(eff_results$plot)
```

## Installation

### Python Dependencies
```bash
pip install -r requirements.txt
```

### R Dependencies
```r
# Install CRAN packages
install.packages(c("ggplot2", "dplyr", "tidyr", "pheatmap"))

# Install Bioconductor packages
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("DESeq2", "edgeR"))

# Optional: for GSEA
BiocManager::install("fgsea")
```

## Example Data Formats

### RNA-seq Count Matrix (CSV)
```
,Sample1,Sample2,Sample3,Sample4
Gene1,1523,1689,234,198
Gene2,456,512,2341,2156
Gene3,89,92,45,51
```

### qPCR Ct Values (CSV)
```
,Ctrl_1,Ctrl_2,Ctrl_3,Treat_1,Treat_2,Treat_3
GAPDH,18.5,18.3,18.6,18.4,18.7,18.5
ACTB,19.2,19.4,19.1,19.3,19.5,19.2
Target1,24.5,24.8,24.3,21.2,21.5,21.1
Target2,26.1,25.9,26.3,22.4,22.7,22.3
```

## Key Features

### RNA-seq Analysis
- Multiple normalization methods (TPM, FPKM, CPM)
- Differential expression with FDR correction
- Comprehensive QC metrics
- Publication-quality visualizations
- PCA for sample clustering
- Support for both Python and R workflows

### qPCR Analysis
- Delta-delta Ct method (2^-ddCt)
- Multiple reference gene support
- Statistical testing (t-test, ANOVA)
- Outlier detection in technical replicates
- Amplification efficiency calculation
- Automatic FDR correction
- Significance indicators in plots

## Notes

- All statistical tests include FDR correction using the Benjamini-Hochberg method
- Visualization functions return matplotlib/ggplot2 objects that can be further customized
- Error handling and NA value management is built into all functions
- Compatible with standard RNA-seq and qPCR data formats

## Support

For questions or issues with the RNA-seq and qPCR analysis tools, please refer to the function docstrings or create an issue in the repository.
