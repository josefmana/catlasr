# catlasr
A compilation of R functions for the CATLAS project

Includes:

- **Forward blocking-related data (from the literature)**  
  (`data(fb_designs)`, `data(fb_effects)`):
  contains summaries of experimental designs used for studying the forward
  blocking phenomenon as well as previously observed effect sizes
- **Forward blocking experimental data**  
  (`data(fb_online_replication)`:
  contains anonymised meta-data, trial-level raw data, and participant-wise
  stimuli mapping from experiments conducted directly for the CATLAS project.
- **Composited stimulus generation**  
  (`catlas_stimulus()`, `render_stimulus()`, `write_stimulus()`):  
  bind text labels to images with fine control over layout, typography
  and vertical positioning (top or bottom)
- **Visual identity for tables**  
  (`apa_style()`)
