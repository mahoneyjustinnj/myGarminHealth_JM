"""
qPCR Data Analysis Module

This module provides functions for analyzing quantitative PCR (qPCR) data including:
- Delta-delta Ct calculations
- Relative expression quantification
- Statistical analysis
- Visualization functions
"""

import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns


def calculate_delta_ct(ct_data, reference_genes):
    """
    Calculate delta Ct values (Ct_target - Ct_reference).
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    reference_genes : list
        List of reference (housekeeping) gene names
    
    Returns:
    --------
    pd.DataFrame
        Delta Ct values for target genes
    """
    # Calculate mean Ct of reference genes
    ref_ct = ct_data.loc[reference_genes].mean(axis=0)
    
    # Get target genes (non-reference genes)
    target_genes = [g for g in ct_data.index if g not in reference_genes]
    
    # Calculate delta Ct for each target gene
    delta_ct = ct_data.loc[target_genes].sub(ref_ct, axis=1)
    
    return delta_ct


def calculate_delta_delta_ct(ct_data, reference_genes, control_samples, 
                             treatment_samples=None):
    """
    Calculate delta-delta Ct and fold change (2^-ddCt method).
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    reference_genes : list
        List of reference (housekeeping) gene names
    control_samples : list
        List of control sample names
    treatment_samples : list, optional
        List of treatment sample names. If None, uses all non-control samples
    
    Returns:
    --------
    pd.DataFrame
        Results containing delta_delta_ct and fold_change
    """
    # Calculate delta Ct
    delta_ct = calculate_delta_ct(ct_data, reference_genes)
    
    # Identify treatment samples if not provided
    if treatment_samples is None:
        treatment_samples = [s for s in delta_ct.columns if s not in control_samples]
    
    # Calculate mean delta Ct for control group
    control_mean_delta_ct = delta_ct[control_samples].mean(axis=1)
    
    # Calculate delta-delta Ct
    delta_delta_ct = delta_ct.sub(control_mean_delta_ct, axis=0)
    
    # Calculate fold change (2^-ddCt)
    fold_change = 2 ** (-delta_delta_ct)
    
    # Create results DataFrame
    results = pd.DataFrame()
    results['control_mean_dCt'] = control_mean_delta_ct
    
    for sample in delta_ct.columns:
        results[f'{sample}_dCt'] = delta_ct[sample]
        results[f'{sample}_ddCt'] = delta_delta_ct[sample]
        results[f'{sample}_fold_change'] = fold_change[sample]
    
    # Calculate mean fold change for treatment group
    treatment_fc_cols = [f'{s}_fold_change' for s in treatment_samples]
    results['treatment_mean_fold_change'] = results[treatment_fc_cols].mean(axis=1)
    results['treatment_sem_fold_change'] = results[treatment_fc_cols].sem(axis=1)
    
    return results


def calculate_relative_expression(ct_target, ct_reference):
    """
    Calculate relative expression using 2^-delta Ct method.
    
    Parameters:
    -----------
    ct_target : pd.Series or pd.DataFrame
        Ct values for target gene(s)
    ct_reference : pd.Series or float
        Ct values for reference gene(s) or mean reference Ct
    
    Returns:
    --------
    pd.Series or pd.DataFrame
        Relative expression values
    """
    delta_ct = ct_target - ct_reference
    relative_expression = 2 ** (-delta_ct)
    return relative_expression


def qpcr_ttest(ct_data, reference_genes, control_samples, treatment_samples):
    """
    Perform t-test on delta Ct values between control and treatment groups.
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    reference_genes : list
        List of reference gene names
    control_samples : list
        List of control sample names
    treatment_samples : list
        List of treatment sample names
    
    Returns:
    --------
    pd.DataFrame
        Statistical test results
    """
    # Calculate delta Ct
    delta_ct = calculate_delta_ct(ct_data, reference_genes)
    
    results = []
    
    for gene in delta_ct.index:
        control_dct = delta_ct.loc[gene, control_samples].values
        treatment_dct = delta_ct.loc[gene, treatment_samples].values
        
        # Perform t-test
        t_stat, p_val = stats.ttest_ind(control_dct, treatment_dct)
        
        # Calculate fold change
        fc = 2 ** (-(treatment_dct.mean() - control_dct.mean()))
        
        results.append({
            'gene': gene,
            'control_mean_dCt': control_dct.mean(),
            'treatment_mean_dCt': treatment_dct.mean(),
            'fold_change': fc,
            't_statistic': t_stat,
            'p_value': p_val
        })
    
    results_df = pd.DataFrame(results).set_index('gene')
    
    # FDR correction
    from statsmodels.stats.multitest import multipletests
    _, results_df['p_adjusted'], _, _ = multipletests(
        results_df['p_value'], 
        method='fdr_bh'
    )
    
    return results_df


def qpcr_anova(ct_data, reference_genes, sample_groups):
    """
    Perform one-way ANOVA on delta Ct values across multiple groups.
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    reference_genes : list
        List of reference gene names
    sample_groups : dict
        Dictionary mapping group names to lists of sample names
    
    Returns:
    --------
    pd.DataFrame
        ANOVA results
    """
    # Calculate delta Ct
    delta_ct = calculate_delta_ct(ct_data, reference_genes)
    
    results = []
    
    for gene in delta_ct.index:
        # Prepare data for ANOVA
        group_data = [delta_ct.loc[gene, samples].values 
                     for samples in sample_groups.values()]
        
        # Perform ANOVA
        f_stat, p_val = stats.f_oneway(*group_data)
        
        results.append({
            'gene': gene,
            'f_statistic': f_stat,
            'p_value': p_val
        })
    
    results_df = pd.DataFrame(results).set_index('gene')
    
    # FDR correction
    from statsmodels.stats.multitest import multipletests
    _, results_df['p_adjusted'], _, _ = multipletests(
        results_df['p_value'], 
        method='fdr_bh'
    )
    
    return results_df


def plot_qpcr_bar(fold_changes, errors=None, title='qPCR Fold Change',
                  ylabel='Fold Change (2^-ddCt)', figsize=(10, 6),
                  p_values=None, p_threshold=0.05):
    """
    Create a bar plot for qPCR fold change data.
    
    Parameters:
    -----------
    fold_changes : pd.Series or dict
        Fold change values for each gene
    errors : pd.Series or dict, optional
        Error values (SEM or SD) for error bars
    title : str
        Plot title
    ylabel : str
        Y-axis label
    figsize : tuple
        Figure size
    p_values : pd.Series or dict, optional
        P-values for significance stars
    p_threshold : float
        P-value threshold for significance
    
    Returns:
    --------
    matplotlib.figure.Figure
        Bar plot figure
    """
    if isinstance(fold_changes, dict):
        fold_changes = pd.Series(fold_changes)
    
    fig, ax = plt.subplots(figsize=figsize)
    
    x_pos = np.arange(len(fold_changes))
    bars = ax.bar(x_pos, fold_changes.values, alpha=0.7, 
                  color='steelblue', edgecolor='black')
    
    # Add error bars if provided
    if errors is not None:
        if isinstance(errors, dict):
            errors = pd.Series(errors)
        ax.errorbar(x_pos, fold_changes.values, yerr=errors.values,
                   fmt='none', ecolor='black', capsize=5, capthick=2)
    
    # Add significance stars if p-values provided
    if p_values is not None:
        if isinstance(p_values, dict):
            p_values = pd.Series(p_values)
        
        max_y = fold_changes.values.max()
        if errors is not None:
            max_y += errors.values.max()
        
        for i, (gene, p_val) in enumerate(p_values.items()):
            if p_val < p_threshold:
                stars = '***' if p_val < 0.001 else ('**' if p_val < 0.01 else '*')
                ax.text(i, max_y * 1.05, stars, ha='center', fontsize=14)
    
    ax.set_xticks(x_pos)
    ax.set_xticklabels(fold_changes.index, rotation=45, ha='right')
    ax.set_ylabel(ylabel, fontsize=12)
    ax.set_title(title, fontsize=14)
    ax.axhline(y=1, color='red', linestyle='--', alpha=0.5, label='No change')
    ax.legend()
    ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    return fig


def plot_ct_values(ct_data, gene, sample_groups=None, title=None, figsize=(8, 6)):
    """
    Plot Ct values for a specific gene across samples.
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    gene : str
        Gene name to plot
    sample_groups : dict, optional
        Dictionary mapping group names to lists of sample names
    title : str, optional
        Plot title (defaults to gene name)
    figsize : tuple
        Figure size
    
    Returns:
    --------
    matplotlib.figure.Figure
        Ct values plot
    """
    fig, ax = plt.subplots(figsize=figsize)
    
    gene_data = ct_data.loc[gene]
    
    if sample_groups is not None:
        # Plot grouped data
        positions = []
        labels = []
        data_to_plot = []
        
        for i, (group_name, samples) in enumerate(sample_groups.items()):
            group_data = gene_data[samples].values
            data_to_plot.append(group_data)
            positions.append(i)
            labels.append(group_name)
        
        bp = ax.boxplot(data_to_plot, positions=positions, labels=labels,
                       patch_artist=True)
        
        # Color boxes
        colors = plt.cm.Set3(np.linspace(0, 1, len(sample_groups)))
        for patch, color in zip(bp['boxes'], colors):
            patch.set_facecolor(color)
    else:
        # Plot all samples
        ax.bar(range(len(gene_data)), gene_data.values, alpha=0.7)
        ax.set_xticks(range(len(gene_data)))
        ax.set_xticklabels(gene_data.index, rotation=45, ha='right')
    
    ax.set_ylabel('Ct Value', fontsize=12)
    ax.set_title(title or f'Ct Values - {gene}', fontsize=14)
    ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    return fig


def plot_amplification_efficiency(ct_values, dilutions, gene_name='Gene'):
    """
    Plot standard curve and calculate amplification efficiency.
    
    Parameters:
    -----------
    ct_values : list or np.array
        Ct values for serial dilutions
    dilutions : list or np.array
        Dilution factors (e.g., [1, 10, 100, 1000])
    gene_name : str
        Name of the gene being analyzed
    
    Returns:
    --------
    tuple
        (fig, efficiency, r_squared) - figure, efficiency %, and R²
    """
    # Calculate log10 of dilutions
    log_dilutions = np.log10(dilutions)
    
    # Linear regression
    slope, intercept, r_value, p_value, std_err = stats.linregress(
        log_dilutions, ct_values
    )
    
    # Calculate efficiency: E = 10^(-1/slope) - 1
    efficiency = (10 ** (-1/slope) - 1) * 100
    r_squared = r_value ** 2
    
    # Create plot
    fig, ax = plt.subplots(figsize=(8, 6))
    
    # Plot data points
    ax.scatter(log_dilutions, ct_values, s=100, alpha=0.7, color='blue')
    
    # Plot regression line
    x_fit = np.linspace(log_dilutions.min(), log_dilutions.max(), 100)
    y_fit = slope * x_fit + intercept
    ax.plot(x_fit, y_fit, 'r--', label=f'Fit: y = {slope:.2f}x + {intercept:.2f}')
    
    ax.set_xlabel('Log10(Dilution)', fontsize=12)
    ax.set_ylabel('Ct Value', fontsize=12)
    ax.set_title(f'Standard Curve - {gene_name}\n'
                f'Efficiency: {efficiency:.1f}%, R² = {r_squared:.4f}',
                fontsize=14)
    ax.legend()
    ax.grid(alpha=0.3)
    
    plt.tight_layout()
    return fig, efficiency, r_squared


def detect_outliers(ct_data, method='iqr', threshold=1.5):
    """
    Detect outlier Ct values in replicates.
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    method : str
        Method for outlier detection ('iqr' or 'zscore')
    threshold : float
        Threshold for outlier detection (IQR multiplier or z-score)
    
    Returns:
    --------
    pd.DataFrame
        Boolean DataFrame indicating outliers
    """
    outliers = pd.DataFrame(False, index=ct_data.index, columns=ct_data.columns)
    
    for gene in ct_data.index:
        gene_cts = ct_data.loc[gene]
        
        if method == 'iqr':
            Q1 = gene_cts.quantile(0.25)
            Q3 = gene_cts.quantile(0.75)
            IQR = Q3 - Q1
            lower_bound = Q1 - threshold * IQR
            upper_bound = Q3 + threshold * IQR
            outliers.loc[gene] = (gene_cts < lower_bound) | (gene_cts > upper_bound)
        
        elif method == 'zscore':
            z_scores = np.abs(stats.zscore(gene_cts))
            outliers.loc[gene] = z_scores > threshold
    
    return outliers


def calculate_technical_replicate_cv(ct_data, replicate_groups):
    """
    Calculate coefficient of variation (CV) for technical replicates.
    
    Parameters:
    -----------
    ct_data : pd.DataFrame
        Ct values with genes as rows and samples as columns
    replicate_groups : dict
        Dictionary mapping sample names to lists of replicate column names
    
    Returns:
    --------
    pd.DataFrame
        CV values for each gene and sample
    """
    cv_results = pd.DataFrame()
    
    for sample_name, replicates in replicate_groups.items():
        replicate_data = ct_data[replicates]
        
        # Calculate mean and standard deviation
        means = replicate_data.mean(axis=1)
        stds = replicate_data.std(axis=1)
        
        # Calculate CV (%)
        cv = (stds / means) * 100
        cv_results[sample_name] = cv
    
    return cv_results


if __name__ == "__main__":
    # Example usage
    print("qPCR Analysis Module")
    print("Available functions:")
    print("- calculate_delta_ct()")
    print("- calculate_delta_delta_ct()")
    print("- calculate_relative_expression()")
    print("- qpcr_ttest()")
    print("- qpcr_anova()")
    print("- plot_qpcr_bar()")
    print("- plot_ct_values()")
    print("- plot_amplification_efficiency()")
    print("- detect_outliers()")
    print("- calculate_technical_replicate_cv()")
