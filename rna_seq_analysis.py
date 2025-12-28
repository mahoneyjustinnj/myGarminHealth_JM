"""
RNA-seq Data Analysis Module

This module provides functions for analyzing RNA sequencing data including:
- Data normalization (TPM, FPKM, CPM)
- Differential expression analysis
- Quality control metrics
- Visualization functions
"""

import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns


def calculate_tpm(counts, gene_lengths):
    """
    Calculate Transcripts Per Million (TPM) normalization.
    
    Parameters:
    -----------
    counts : pd.DataFrame
        Raw count matrix with genes as rows and samples as columns
    gene_lengths : pd.Series or dict
        Gene lengths in base pairs, indexed by gene names
    
    Returns:
    --------
    pd.DataFrame
        TPM-normalized expression matrix
    """
    # Convert gene_lengths to Series if it's a dict
    if isinstance(gene_lengths, dict):
        gene_lengths = pd.Series(gene_lengths)
    
    # Align gene lengths with counts
    gene_lengths = gene_lengths.reindex(counts.index)
    
    # Calculate RPK (reads per kilobase)
    rpk = counts.div(gene_lengths / 1000, axis=0)
    
    # Calculate scaling factor (per million)
    scaling_factor = rpk.sum(axis=0) / 1e6
    
    # Calculate TPM
    tpm = rpk.div(scaling_factor, axis=1)
    
    return tpm


def calculate_fpkm(counts, gene_lengths, total_reads=None):
    """
    Calculate Fragments Per Kilobase Million (FPKM) normalization.
    
    Parameters:
    -----------
    counts : pd.DataFrame
        Raw count matrix with genes as rows and samples as columns
    gene_lengths : pd.Series or dict
        Gene lengths in base pairs
    total_reads : pd.Series, optional
        Total reads per sample. If None, calculated from counts
    
    Returns:
    --------
    pd.DataFrame
        FPKM-normalized expression matrix
    """
    if isinstance(gene_lengths, dict):
        gene_lengths = pd.Series(gene_lengths)
    
    gene_lengths = gene_lengths.reindex(counts.index)
    
    if total_reads is None:
        total_reads = counts.sum(axis=0)
    
    # FPKM = (counts * 1e9) / (gene_length * total_reads)
    fpkm = counts.mul(1e9).div(gene_lengths, axis=0).div(total_reads, axis=1)
    
    return fpkm


def calculate_cpm(counts):
    """
    Calculate Counts Per Million (CPM) normalization.
    
    Parameters:
    -----------
    counts : pd.DataFrame
        Raw count matrix with genes as rows and samples as columns
    
    Returns:
    --------
    pd.DataFrame
        CPM-normalized expression matrix
    """
    total_counts = counts.sum(axis=0)
    cpm = counts.div(total_counts, axis=1) * 1e6
    return cpm


def filter_low_expression(counts, min_count=10, min_samples=2):
    """
    Filter out genes with low expression across samples.
    
    Parameters:
    -----------
    counts : pd.DataFrame
        Count matrix with genes as rows and samples as columns
    min_count : int
        Minimum count threshold
    min_samples : int
        Minimum number of samples that must meet the count threshold
    
    Returns:
    --------
    pd.DataFrame
        Filtered count matrix
    """
    keep = (counts >= min_count).sum(axis=1) >= min_samples
    return counts[keep]


def calculate_fold_change(treatment, control, pseudocount=1):
    """
    Calculate log2 fold change between treatment and control groups.
    
    Parameters:
    -----------
    treatment : pd.DataFrame or pd.Series
        Expression values for treatment samples
    control : pd.DataFrame or pd.Series
        Expression values for control samples
    pseudocount : float
        Pseudocount to add before log transformation
    
    Returns:
    --------
    pd.Series
        Log2 fold change values
    """
    if isinstance(treatment, pd.DataFrame):
        treatment_mean = treatment.mean(axis=1)
    else:
        treatment_mean = treatment
    
    if isinstance(control, pd.DataFrame):
        control_mean = control.mean(axis=1)
    else:
        control_mean = control
    
    log2fc = np.log2((treatment_mean + pseudocount) / (control_mean + pseudocount))
    
    return log2fc


def perform_ttest(treatment, control):
    """
    Perform t-test for differential expression analysis.
    
    Parameters:
    -----------
    treatment : pd.DataFrame
        Expression values for treatment samples (genes x samples)
    control : pd.DataFrame
        Expression values for control samples (genes x samples)
    
    Returns:
    --------
    pd.DataFrame
        Results containing t-statistic, p-value, and adjusted p-value
    """
    results = []
    
    for gene in treatment.index:
        t_values = treatment.loc[gene].values
        c_values = control.loc[gene].values
        
        t_stat, p_val = stats.ttest_ind(t_values, c_values)
        
        results.append({
            'gene': gene,
            't_statistic': t_stat,
            'p_value': p_val
        })
    
    results_df = pd.DataFrame(results).set_index('gene')
    
    # FDR correction (Benjamini-Hochberg)
    from statsmodels.stats.multitest import multipletests
    _, results_df['p_adjusted'], _, _ = multipletests(
        results_df['p_value'], 
        method='fdr_bh'
    )
    
    return results_df


def plot_volcano(log2fc, pvalues, fc_threshold=1, p_threshold=0.05, 
                 title='Volcano Plot', figsize=(10, 8)):
    """
    Create a volcano plot for differential expression results.
    
    Parameters:
    -----------
    log2fc : pd.Series
        Log2 fold change values
    pvalues : pd.Series
        P-values (will be converted to -log10)
    fc_threshold : float
        Fold change threshold for significance
    p_threshold : float
        P-value threshold for significance
    title : str
        Plot title
    figsize : tuple
        Figure size
    
    Returns:
    --------
    matplotlib.figure.Figure
        Volcano plot figure
    """
    fig, ax = plt.subplots(figsize=figsize)
    
    # Calculate -log10(p-value)
    neg_log10_p = -np.log10(pvalues)
    
    # Determine significance
    significant = (np.abs(log2fc) >= fc_threshold) & (pvalues <= p_threshold)
    
    # Plot
    colors = ['red' if sig else 'gray' for sig in significant]
    ax.scatter(log2fc, neg_log10_p, c=colors, alpha=0.5, s=20)
    
    # Add threshold lines
    ax.axhline(-np.log10(p_threshold), color='blue', linestyle='--', 
               label=f'p = {p_threshold}')
    ax.axvline(fc_threshold, color='green', linestyle='--', 
               label=f'FC = {fc_threshold}')
    ax.axvline(-fc_threshold, color='green', linestyle='--')
    
    ax.set_xlabel('Log2 Fold Change', fontsize=12)
    ax.set_ylabel('-Log10 P-value', fontsize=12)
    ax.set_title(title, fontsize=14)
    ax.legend()
    ax.grid(alpha=0.3)
    
    plt.tight_layout()
    return fig


def plot_heatmap(expression_data, samples_to_plot=None, genes_to_plot=None,
                 title='Expression Heatmap', figsize=(12, 10)):
    """
    Create a heatmap of expression data.
    
    Parameters:
    -----------
    expression_data : pd.DataFrame
        Expression matrix (genes x samples)
    samples_to_plot : list, optional
        Subset of samples to include
    genes_to_plot : list, optional
        Subset of genes to include
    title : str
        Plot title
    figsize : tuple
        Figure size
    
    Returns:
    --------
    matplotlib.figure.Figure
        Heatmap figure
    """
    # Subset data if specified
    data = expression_data.copy()
    if samples_to_plot is not None:
        data = data[samples_to_plot]
    if genes_to_plot is not None:
        data = data.loc[genes_to_plot]
    
    # Z-score normalization for visualization
    data_zscore = (data - data.mean(axis=1).values.reshape(-1, 1)) / data.std(axis=1).values.reshape(-1, 1)
    
    fig, ax = plt.subplots(figsize=figsize)
    sns.heatmap(data_zscore, cmap='RdBu_r', center=0, 
                cbar_kws={'label': 'Z-score'}, ax=ax)
    ax.set_title(title, fontsize=14)
    ax.set_xlabel('Samples', fontsize=12)
    ax.set_ylabel('Genes', fontsize=12)
    
    plt.tight_layout()
    return fig


def calculate_qc_metrics(counts):
    """
    Calculate quality control metrics for RNA-seq data.
    
    Parameters:
    -----------
    counts : pd.DataFrame
        Raw count matrix
    
    Returns:
    --------
    pd.DataFrame
        QC metrics per sample
    """
    qc_metrics = pd.DataFrame()
    
    qc_metrics['total_reads'] = counts.sum(axis=0)
    qc_metrics['genes_detected'] = (counts > 0).sum(axis=0)
    qc_metrics['median_expression'] = counts.median(axis=0)
    qc_metrics['mean_expression'] = counts.mean(axis=0)
    
    # Top 10 genes percentage
    top10_genes = counts.apply(lambda x: x.nlargest(10).sum() / x.sum() * 100, axis=0)
    qc_metrics['top10_genes_pct'] = top10_genes
    
    return qc_metrics


def plot_pca(expression_data, sample_labels=None, title='PCA Plot', figsize=(10, 8)):
    """
    Perform and plot PCA on expression data.
    
    Parameters:
    -----------
    expression_data : pd.DataFrame
        Expression matrix (genes x samples)
    sample_labels : dict or pd.Series, optional
        Labels for samples for coloring
    title : str
        Plot title
    figsize : tuple
        Figure size
    
    Returns:
    --------
    tuple
        (fig, pc_df) - matplotlib figure and PC coordinates DataFrame
    """
    from sklearn.decomposition import PCA
    from sklearn.preprocessing import StandardScaler
    
    # Transpose and standardize
    data_t = expression_data.T
    scaler = StandardScaler()
    data_scaled = scaler.fit_transform(data_t)
    
    # Perform PCA
    n_components = min(10, data_scaled.shape[0], data_scaled.shape[1])
    pca = PCA(n_components=n_components)
    pc_coords = pca.fit_transform(data_scaled)
    
    # Create DataFrame with results
    pc_df = pd.DataFrame(
        pc_coords[:, :2],
        columns=['PC1', 'PC2'],
        index=expression_data.columns
    )
    
    # Plot
    fig, ax = plt.subplots(figsize=figsize)
    
    if sample_labels is not None:
        if isinstance(sample_labels, dict):
            sample_labels = pd.Series(sample_labels)
        pc_df['label'] = sample_labels.reindex(pc_df.index)
        
        for label in pc_df['label'].unique():
            mask = pc_df['label'] == label
            ax.scatter(pc_df.loc[mask, 'PC1'], pc_df.loc[mask, 'PC2'],
                      label=label, alpha=0.7, s=100)
        ax.legend()
    else:
        ax.scatter(pc_df['PC1'], pc_df['PC2'], alpha=0.7, s=100)
    
    variance_exp = pca.explained_variance_ratio_
    ax.set_xlabel(f'PC1 ({variance_exp[0]*100:.1f}% variance)', fontsize=12)
    ax.set_ylabel(f'PC2 ({variance_exp[1]*100:.1f}% variance)', fontsize=12)
    ax.set_title(title, fontsize=14)
    ax.grid(alpha=0.3)
    
    plt.tight_layout()
    return fig, pc_df


if __name__ == "__main__":
    # Example usage
    print("RNA-seq Analysis Module")
    print("Available functions:")
    print("- calculate_tpm()")
    print("- calculate_fpkm()")
    print("- calculate_cpm()")
    print("- filter_low_expression()")
    print("- calculate_fold_change()")
    print("- perform_ttest()")
    print("- plot_volcano()")
    print("- plot_heatmap()")
    print("- calculate_qc_metrics()")
    print("- plot_pca()")
