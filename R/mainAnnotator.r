#' Annotation and visualisation of Bionano SV.
#'
#' @param method  character. Input Method for terms. Choices are 
#'                "Single","Multiple" and "Text".
#' @param termPath  character. Path and file name for textfile.
#' @param terms  character. Single or Multiple Terms.
#' @param outpath character. Path where gene lists are saved.
#' @param thresh integer. Threshold for the number of terms sent to entrez.
#'                Note if large lists are sent to ncbi, it might fail to get
#'                processed. Default is 5.
#' @param smap  character. Path to SMAP file.
#' @param bed  Text Bionano Bed file.
#' @param inputfmt character Whether the bed input is UCSC bed or Bionano bed.
#' @param outpath  character Path for the output files.
#' @param n  numeric Number of genes to report which are nearest to the breakpoint.
#' Default is  	3.
#' @param returnMethod Character. Type of output Dataframe or in Text format.
#' @param mergedFiles  character. Path to the merged SV files.
#' @param smappath  character. path to the query smap file.
#' @param smap  character. File name for the smap
#' @param buildSVInternalDB  boolean. Checking whether the merged solo 
#' file database exist.
#' @param inputfmt character. Choice between Text and DataFrame.
#' @param path  character. Path to the solo file database.
#' @param pattern  character. pattern of the file names to merge.
#' @param outpath  character. Path to merged SV solo datasets.
#' @param win_indel  Numeric. Insertion and deletion error window.
#' @param win_inv_trans  Numeric. Inversion and translocation error window.
#' @param perc_similarity  Numeric . ThresholdPercentage similarity 
#' of the query SV and reference SV.
#' @param indelconf  Numeric. Threshold for insertion and deletion confidence.
#' @param indelconf  Numeric. Threshold for inversion confidence.
#' @param indelconf  Numeric. Threshold for translocation confidence.
#' @param returnMethod character. Choice between Text and DataFrame.
#' @param hgpath  character. Path to Database of Genomic Variants (DGV)
#'                Text file. 
#' @param smappath  character. Path and file name for textfile.
#' @param terms  character. Single or Multiple Terms.
#' @param outpath character. Path where gene lists are saved.
#' @param input_fmt character. Choice between text or data frame as 
#' an input to the DGV frequency calculator.
#' @param smap_data Dataset containing smap data.
#' @param thresh integer. Threshold for the number of terms sent to entrez.
#'                Note if large lists are sent to ncbi, it might fail to get
#'                processed. Default is 5.
#' @param returnMethod character. Choice between text or data frame as the output.
#' @param input_fmt_geneList character. Choice of gene list input 
#'        Text or Dataframe.
#' @param input_fmt_svMap  character. Choice of gene list input 
#'        Text or Dataframe.
#' @param SVFile  character. SV file name.
#' @param svData Dataframe Input data containing SV data.
#' @param dat_geneList Dataframe Input data containing geneList data.
#' @param fileName Character Name of file containing Gene List data.
#' @param outpath Character Directory to the output file.
#' @param outFileName Character Output filename.
#' @return Excel file containing the annotated SV map, tabs divided based on
#' type of SVs.
#' @return Text files containg gene list and terms associated with them
#'         are stored as text files.
#' @examples
#' \dontrun{
#' }
#' @export
nanotatoR_main<-function(
	smap, bed, inputfmt = c("bed", "BNBed"), n=3, mergedFiles , smappath ,buildSVInternalDB=FALSE, path, pattern, 
	win_indel_INF = 10000, win_inv_trans_INF = 50000, perc_similarity_INF= 0.5, indelconf = 0.5, invconf = 0.01, 
	transconf = 0.1, hgpath, win_indel_DGV = 10000, win_inv_trans_DGV = 50000, perc_similarity_DGV = 0.5,method=c("Text","Single","Multiple"), smapName,termPath, term, thresh=5,outpath,outputFilename="")
	{
	
	 dat_geneList<-gene_list_generation(method="Text",termPath=termPath,returnMethod="dataFrame")
	 datcompSmap<-compSmapbed(smap=smap,bed=bed, inputfmt="bed",n=5,returnMethod="dataFrame") 
	 datDGV<- DGV_extraction(hgpath=hgpath, smap_data=datcompSmap,input_fmt=c("DataFrame"),
     win_indel = win_indel_DGV, win_inv_trans = win_inv_trans_DGV, 
	 perc_similarity = perc_similarity_DGV,returnMethod=c("dataFrame"))
	 if(buildSVInternalDB==FALSE){
	    datInf<-internalFrequency(mergedFiles=mergedFiles , buildSVInternalDB=FALSE, smapdata=datDGV, input_fmt="dataFrame", smapName,                
		win_indel = win_indel_INF, win_inv_trans = win_inv_trans_INF, 
		perc_similarity =perc_similarity_INF, indelconf , invconf , transconf ,returnMethod="dataFrame")
		}
	else{
	    datInf<-internalFrequency(buildSVInternalDB=TRUE, path, pattern, outpath,  
		smapdata=datDGV, input_fmt="dataFrame", win_indel=win_indel_INF, 
		win_inv_trans=win_inv_trans_INF, perc_similarity=perc_similarity_INF, indelconf , invconf, transconf, 
		returnMethod=c("dataFrame"))
	      
	}
	run_bionano_filter(input_fmt_geneList="dataFrame",input_fmt_svMap="dataFrame",
                    SVFile=NULL,svData=datRNASeq,dat_geneList=dat_geneList,outpath="C://Annotator//Data//",outputFilename="F1.1_UDN287643_P")
	}
        	 
	