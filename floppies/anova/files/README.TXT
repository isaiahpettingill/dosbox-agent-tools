ONE-WAY ANOVA

Run ANOVA. Enter a data filename, or press Enter to use the keyboard.
Then follow the prompts. Enter one number per line:
number of groups, first group size, its observations, next group size,
and so on. Supports 2-10 groups, 1-100 observations per group, and
unequal group sizes. At least one group must have multiple observations.

Enter KNOWN.TXT at the filename prompt. This example gives between-group
SS=24, within-group SS=6, total SS=30, df=2 and 6, and F=12.

Reports group means and the ANOVA table. Compare F with an F distribution
table using the between and within degrees of freedom. No p-value or
automatic significance decision is computed. If within variance is zero,
F is reported as undefined.

The ordinary one-way ANOVA F test assumes independent observations,
normally distributed errors, and equal population variances.
This is not a repeated-measures, Welch, or multi-factor ANOVA.

Built with Microsoft FORTRAN 5.0 for real-mode DOS using software floating
point; an 8087 coprocessor is not required. Source is ANOVA.FOR.
