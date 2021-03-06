% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RNASEQ_Analysis_solo_SVMerge_SE.r
\name{SVexpression_solo}
\alias{SVexpression_solo}
\title{Annotating the Overlapping and Non-Overlapping genes with RNAseq expression}
\usage{
SVexpression_solo(
  input_fmt_SV = c("Text", "dataFrame"),
  smapdata,
  smappath,
  input_fmt_RNASeq = c("Text", "dataFrame"),
  RNASeqData,
  RNASeqPATH,
  outputfmt = c("Text", "datFrame"),
  pattern_Proband = NA,
  EnzymeType = c("SVMerge", "SE")
)
}
\arguments{
\item{input_fmt_SV}{character. Input format of the SV data.Options 
"Text" or "DataFrame".}

\item{smapdata}{dataframe. SV data dataframe.}

\item{smappath}{character. smap path.}

\item{input_fmt_RNASeq}{character. Input format of
the RNASeq data. Options "Text" or "DataFrame"..}

\item{RNASeqData}{dataFrame. RNAseq data with gene names.}

\item{RNASeqPATH}{character. RNAseq dataset path .}

\item{outputfmt}{character. Output format of
the result. Options "Text" or "DataFrame"..}

\item{pattern_Proband}{character. Pattern for proband.}

\item{EnzymeType}{character. Enzyme used. option "SVMerge" or "SE".}
}
\value{
Dataframe Annotated datafreme with RNASeq data.
}
\description{
Annotating the Overlapping and Non-Overlapping genes with RNAseq expression
}
\examples{
RNASeqDir = system.file("extdata", package="nanotatoR")
returnMethod="dataFrame"
datRNASeq <- RNAseqcombine_solo(RNASeqDir = RNASeqDir,
returnMethod = returnMethod)
smapName="NA12878_DLE1_VAP_solo5.smap"
smap = system.file("extdata", smapName, package="nanotatoR")
smap = system.file("extdata", smapName, package="nanotatoR")
bedFile <- system.file("extdata", "HomoSapienGRCH19_lift37.bed", package="nanotatoR")
outpath <- system.file("extdata", package="nanotatoR")
datcomp<-overlapnearestgeneSearch(smap = smap, 
    bed=bedFile, inputfmtBed = "bed", outpath, 
    n = 3, returnMethod_bedcomp = c("dataFrame"), 
    input_fmt_SV = "Text",
    EnzymeType = "SE", 
    bperrorindel = 3000, 
    bperrorinvtrans = 50000)
datRNASeq1 <- SVexpression_solo (input_fmt_SV=c("dataFrame"),
    smapdata = datcomp,
    input_fmt_RNASeq=c("dataFrame"),
    RNASeqData = datRNASeq,
    outputfmt=c("datFrame"),
    pattern_Proband = "*_P_*", EnzymeType = c("SE"))
datRNASeq1[1,]
}
