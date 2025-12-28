"""
Example script demonstrating RNA-seq data analysis
"""

import pandas as pd
import matplotlib.pyplot as plt
from rna_seq_analysis import *

# Load example data
print("Loading example RNA-seq data...")
counts = pd.read_csv('example_rnaseq_counts.csv', index_col=0)
gene_lengths = pd.read_csv('example_gene_lengths.csv', index_col=0)['length']

print(f"Count matrix shape: {counts.shape}")
print(f"Samples: {list(counts.columns)}")
print()

# Define sample groups
control_samples = ['Control_1', 'Control_2', 'Control_3']
treatment_samples = ['Treatment_1', 'Treatment_2', 'Treatment_3']

# 1. Calculate QC metrics
print("=== Quality Control Metrics ===")
qc_metrics = calculate_qc_metrics(counts)
print(qc_metrics)
print()

# 2. Filter low expression genes
print("=== Filtering Low Expression Genes ===")
print(f"Genes before filtering: {len(counts)}")
filtered_counts = filter_low_expression(counts, min_count=100, min_samples=2)
print(f"Genes after filtering: {len(filtered_counts)}")
print()

# 3. Normalize using TPM
print("=== TPM Normalization ===")
tpm = calculate_tpm(filtered_counts, gene_lengths)
print(tpm.head())
print()

# 4. Calculate CPM
print("=== CPM Normalization ===")
cpm = calculate_cpm(filtered_counts)
print(cpm.head())
print()

# 5. Differential expression analysis
print("=== Differential Expression Analysis ===")
treatment_data = filtered_counts[treatment_samples]
control_data = filtered_counts[control_samples]

# Calculate fold change
fc = calculate_fold_change(treatment_data, control_data)
print("Log2 Fold Changes:")
print(fc.sort_values(ascending=False))
print()

# Perform t-test
de_results = perform_ttest(treatment_data, control_data)
print("Differential Expression Results:")
print(de_results.sort_values('p_adjusted'))
print()

# Identify significant genes
sig_genes = de_results[de_results['p_adjusted'] < 0.05]
print(f"Number of significant genes (FDR < 0.05): {len(sig_genes)}")
print()

# 6. Create visualizations
print("=== Creating Visualizations ===")

# Volcano plot
print("Creating volcano plot...")
fig1 = plot_volcano(fc, de_results['p_adjusted'], 
                    fc_threshold=1, p_threshold=0.05,
                    title='RNA-seq Volcano Plot')
fig1.savefig('volcano_plot_example.png', dpi=300, bbox_inches='tight')
print("Saved: volcano_plot_example.png")

# Heatmap of top variable genes
print("Creating heatmap...")
fig2 = plot_heatmap(tpm, title='Top Variable Genes Heatmap', figsize=(10, 8))
fig2.savefig('heatmap_example.png', dpi=300, bbox_inches='tight')
print("Saved: heatmap_example.png")

# PCA plot
print("Creating PCA plot...")
sample_labels = {
    'Control_1': 'Control', 'Control_2': 'Control', 'Control_3': 'Control',
    'Treatment_1': 'Treatment', 'Treatment_2': 'Treatment', 'Treatment_3': 'Treatment'
}
fig3, pc_df = plot_pca(tpm, sample_labels=sample_labels, title='PCA - RNA-seq Data')
fig3.savefig('pca_plot_example.png', dpi=300, bbox_inches='tight')
print("Saved: pca_plot_example.png")
print()

print("=== Analysis Complete ===")
print("Generated files:")
print("  - volcano_plot_example.png")
print("  - heatmap_example.png")
print("  - pca_plot_example.png")
