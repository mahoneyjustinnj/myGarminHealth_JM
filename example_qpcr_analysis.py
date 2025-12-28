"""
Example script demonstrating qPCR data analysis
"""

import pandas as pd
import matplotlib.pyplot as plt
from qpcr_analysis import *

# Load example qPCR data
print("Loading example qPCR data...")
ct_data = pd.read_csv('example_qpcr_ct.csv', index_col=0)

print(f"Ct data shape: {ct_data.shape}")
print(f"Genes: {list(ct_data.index)}")
print(f"Samples: {list(ct_data.columns)}")
print()

# Display raw Ct values
print("=== Raw Ct Values ===")
print(ct_data)
print()

# Define experimental setup
reference_genes = ['GAPDH', 'ACTB']
control_samples = ['Ctrl_1', 'Ctrl_2', 'Ctrl_3']
treatment_samples = ['Treat_1', 'Treat_2', 'Treat_3']

print("Experimental Setup:")
print(f"  Reference genes: {reference_genes}")
print(f"  Control samples: {control_samples}")
print(f"  Treatment samples: {treatment_samples}")
print()

# 1. Calculate delta Ct
print("=== Delta Ct Calculation ===")
delta_ct = calculate_delta_ct(ct_data, reference_genes)
print("Delta Ct values (Target - Reference):")
print(delta_ct)
print()

# 2. Calculate delta-delta Ct and fold change
print("=== Delta-Delta Ct and Fold Change ===")
ddct_results = calculate_delta_delta_ct(ct_data, reference_genes, 
                                        control_samples, treatment_samples)
print(ddct_results)
print()

# 3. Statistical testing
print("=== Statistical Analysis (t-test) ===")
stats_results = qpcr_ttest(ct_data, reference_genes, 
                           control_samples, treatment_samples)
print(stats_results)
print()

# Identify significant genes
sig_genes = stats_results[stats_results['p_adjusted'] < 0.05]
print(f"Number of significant genes (FDR < 0.05): {len(sig_genes)}")
if len(sig_genes) > 0:
    print("Significant genes:")
    print(sig_genes[['fold_change', 'p_value', 'p_adjusted']])
print()

# 4. Create visualizations
print("=== Creating Visualizations ===")

# Bar plot with fold changes
print("Creating fold change bar plot...")
fig1 = plot_qpcr_bar(
    stats_results['fold_change'],
    errors=ddct_results['treatment_sem_fold_change'],
    p_values=stats_results['p_adjusted'],
    title='qPCR Fold Change Analysis',
    p_threshold=0.05
)
fig1.savefig('qpcr_bar_plot_example.png', dpi=300, bbox_inches='tight')
print("Saved: qpcr_bar_plot_example.png")

# Ct values for a specific gene
print("Creating Ct values plot...")
sample_groups = {
    'Control': control_samples,
    'Treatment': treatment_samples
}
fig2 = plot_ct_values(ct_data, 'IL6', sample_groups=sample_groups,
                      title='Ct Values - IL6')
fig2.savefig('ct_values_example.png', dpi=300, bbox_inches='tight')
print("Saved: ct_values_example.png")

# 5. Quality control - check for outliers
print("\n=== Quality Control ===")
outliers = detect_outliers(ct_data, method='iqr', threshold=1.5)
print("Outlier detection (IQR method):")
print(outliers)
if outliers.any().any():
    print("\nOutliers detected:")
    for gene in outliers.index:
        for sample in outliers.columns:
            if outliers.loc[gene, sample]:
                print(f"  {gene} in {sample}: Ct = {ct_data.loc[gene, sample]}")
else:
    print("No outliers detected.")
print()

# 6. Calculate technical replicate CV
print("=== Technical Replicate Quality ===")
# For demonstration, treat control and treatment as separate replicate groups
replicate_groups = {
    'Control': control_samples,
    'Treatment': treatment_samples
}
cv_results = calculate_technical_replicate_cv(ct_data, replicate_groups)
print("Coefficient of Variation (CV %) for replicates:")
print(cv_results)
print()

# 7. Amplification efficiency example (using hypothetical standard curve data)
print("=== Amplification Efficiency Example ===")
# Example standard curve data
ct_values = [15.2, 18.5, 22.1, 25.3]
dilutions = [1, 10, 100, 1000]

fig3, efficiency, r_squared = plot_amplification_efficiency(
    ct_values, dilutions, gene_name='IL6'
)
fig3.savefig('efficiency_curve_example.png', dpi=300, bbox_inches='tight')
print(f"Amplification Efficiency: {efficiency:.2f}%")
print(f"R-squared: {r_squared:.4f}")
print("Saved: efficiency_curve_example.png")
print()

print("=== Analysis Complete ===")
print("Generated files:")
print("  - qpcr_bar_plot_example.png")
print("  - ct_values_example.png")
print("  - efficiency_curve_example.png")
print()
print("Summary:")
print(f"  Total genes analyzed: {len(delta_ct)}")
print(f"  Significant genes (FDR < 0.05): {len(sig_genes)}")
print(f"  Average fold change: {stats_results['fold_change'].mean():.2f}")
