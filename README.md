# CPMORS (Conformal Predictor for MOrtality Risk in Sepsis)
## Brief Introduction
We aimed to develop and validate an AI model, called CPMORS (Conformal Predictor for MOrtality Risk in Sepsis), to assess the risk of in-hospital sepsis mortality in ICU admissions. We expected the model to provide confidence measures to monitor predictions and flag uncertain predictions at a customized confidence level for human intervention, as well as to provide interpretable risk factors. Through combining model explanation and uncertainty analysis, we aimed at improving the translation of AI-assisted sepsis prediction systems into medical practice and enable intensivists to use them in clinical decision-making.
![Visualization of the use of CPMORS in AI-assisted sepsis mortality risk prediction. The implication of multiple predictions is that there is insufficient information for the model to discriminate between survival and non-survival outcomes, which are flagged for human review. Risk factors are the explanations provided by the Sharply values. Risk factors in red are more serious and risk factors in green are in the normal range.](https://github.com/Meicheng-SEU/CPMORS/blob/main/Visualization%20of%20the%20use%20of%20CPMORS%20in%20AI-assisted%20sepsis%20mortality%20risk%20prediction.png)

## Data source and extraction
The MIMIC-IV data used in this present study can be retrieved from [https://physionet.org/content/mimiciv/2.2/](https://physionet.org/content/mimiciv/2.2/). eICU-CRD data: [http://eicu-crd.mit.edu/](https://physionet.org/content/eicu-crd/2.0/).

Details of how to extract data from MIMIC-IV and eICU-CRD have been provided in SQL in the **data_extraction** folder.

## Predictive model and uncertainty estimation
The code for building the predictive model and uncertainty estimation can be found in the **model** folder.
