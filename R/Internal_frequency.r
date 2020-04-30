#' Merges Solo SV files to one common SV file
#'
#' @param path  character. Path to the solo files.
#' @param pattern  character. file name pattern for solo files.
#' @return Text file containing all the solo SMAP files.
#' @examples
#' \dontrun{
#' path="Z:/Hayks_Materials/Bionano/Projects/UDN/VSVM_Solo"
#' pattern="_solo.txt"
#' makeMergedSVData(path, pattern, outpath=systemDir())
#'}
#' @export
makeMergedSVData <- function(path, pattern, outpath) {
    setwd(path)
    l <- list.files(".", pattern)
    nam <- c()
    datfinal <- data.frame()
    for (ii in 1:length(l)) {
        #### print(l[ii])
        con <- file(l[ii], "r")
        r10 <- readLines(con, n = -1)
        close(con)
        g1 <- grep("RefEndPos", r10)
        g2 <- grep("RefStartPos", r10)
        # r10<-as.character(r10)
        if (g1 == g2) {
            dat <- gsub("# ", "", as.character(r10))
            # dat<-gsub('\t',' ',as.character(dat))
            dat4 <- textConnection(dat[g1:length(dat)])
            ##### print(dim(dat4))
            r1 <- read.table(dat4, sep = "\t", header = TRUE)
            nam <- names(r1)
            r1 <- data.frame(r1)
            st <- strsplit(l[ii], split = ".txt")
            fname <- st[[1]][1]
            fname1 <- c(rep(fname, length(r1[, 1])))
            r1 <- cbind(fname1, r1)
            #### print(dim(r1))
            datfinal <- data.frame(rbind(datfinal, r1))
            #### print(dim(datfinal))
        } else {
            stop("column names doesnot Match")
        }
    }
    nam1 <- c("SVIdentifier", nam)
    names(datfinal) <- nam1
    st <- strsplit(path, split = "/")
    fname <- st[[1]][3]
    filename <- paste(fname, "_merged.txt", sep = "")
    write.table(datfinal, file.path(outpath, filename), sep = "\t")
    return(datfinal)
}

#' Calculates the internal frequencies of SV in internal cohorts
#'
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
#' @return Text file or data frames containing internalFrequency data.
#' @examples
#' \dontrun{
#' mergedFiles = "Z:/bionano/VSVM_Solo/UDN_Samples_Meged.txt"
#' smappath = "Z:\\bionano\\"
#' win_indel = 10000; win_inv_trans = 50000; perc_similarity = 0.5;
#' indelconf = 0.5; invconf = 0.01;transconf = 0.1
#' internalFrequency(mergedFiles , smappath , buildSVInternalDB=FALSE, 
#' win_indel, win_inv_trans, perc_similarity , indelconf, invconf , 
#' transconf,returnMethod="dataFrame")
#' }
#' @export
internalFrequency <- function(mergedFiles, smappath , smapFileName , buildSVInternalDB=FALSE, smapdata,smapName, input_fmt=c("Text","dataFrame"), path, pattern, outpath, win_indel = 10000, win_inv_trans = 50000, 
	perc_similarity = 0.5, indelconf = 0.5, invconf = 0.01, transconf = 0.1,returnMethod=c("Text","dataFrame"))
    {
    #library(hash)
	print("###Internal Frequency Calculation###")
    if(buildSVInternalDB==TRUE){
	    r<-makeMergedSVData(path, pattern, outpath)
	} else{
	    r <- read.table(mergedFiles, sep = "\t", header = TRUE)
	}
    usamp <- length(unique(r$SVIdentifier))
    if(input_fmt=="Text"){
	con <- file(paste(smappath, smapFileName, sep = ""), "r")
    r10 <- readLines(con, n = -1)
    close(con)
    # datfinal<-data.frame()
    g1 <- grep("RawConfidence", r10)
    g2 <- grep("RefStartPos", r10)
    if (g1 == g2)
    {
        dat <- gsub("# ", "", as.character(r10))
        # dat<-gsub('\t',' ',r10)
        dat4 <- textConnection(dat[g1:length(dat)])
        r1 <- read.table(dat4, sep = "\t", header = TRUE)
    } else
    {
        stop("column names doesnot Match")
    }
    }
	else if(input_fmt=="dataFrame"){
	r1<-smapdata
	smapFileName<-smapName
	}
	else{
	stop("Input Format incorrect")
	}
    ufam <- as.character(unique(r$SVIdentifier))
    famid <- c()
    for (ii in 1:length(ufam))
    {
        stt <- strsplit(ufam[[ii]][1], split = "[.]")
        famid <- c(famid, as.character(stt[[1]][1]))
    }
    datf1 <- data.frame(table(famid))
    ha <- hash()
    .set(ha, keys = as.character(datf1$famid), values = as.character(datf1$Freq))
    ## Checking Sex male/female and assigning chromosome number accordingly
    chro <- length(unique(r1$RefcontigID1))
    chro1 <- c(1:chro)
	#print(chro1)
    dataFinal <- c()
	
    for (ii in 1:length(chro1))
    {
        #print(paste('Chrom:',ii,sep=''))
        dat <- r[which(r$RefcontigID1 == ii), ]
        #print(dat[1,])
        # variantType1<-dat$variantsubtype 
		##Changing the variant terms in DGV to match svmap
        variantType1 <- dat$Type
		#print(variantType1[1:10])
        BSPQI_status_DB <- as.character(dat$Found_in_self_BSPQI_molecules)
        BSSSI_status_DB <- as.character(dat$Found_in_self_BSSSI_molecules)
        ## Extracting data from SVmap
        dat1 <- r1[which(r1$RefcontigID1 == chro1[ii]), ]
		#print(dat1[1,])
        ## Adding the windows to the breakpoints
        rf <- dat1$RefStartPos
		#print(rf[1:10])
        rf_wb_ind <- rf - win_indel
		#print(rf_wb_ind[1:10])
        rf_fb_ind <- rf + win_indel
        rf_wb_int <- rf - win_inv_trans
        rf_fb_int <- rf + win_inv_trans
        re <- dat1$RefEndPos
        re_wf_ind <- re + win_indel
        re_wb_ind <- re - win_indel
        re_wb_int <- re - win_inv_trans
        re_fb_int <- re + win_inv_trans
        ## Calculating size
        size_bn <- dat1$Size
        conf1 <- dat1$Confidence
        variantType2 <- as.character(dat1$Type)
        # svfam<-as.character(dat1$SVIdentifier)
		
        # svind<-dat1$SVIndex
        BSPQI_status_Query <- as.character(dat1$Found_in_self_BSPQI_molecules)
        BSSSI_status_Query <- as.character(dat1$Found_in_self_BSSSI_molecules)
		#print(smapFileName)
        if((length(grep("\\\\",smapFileName))>=1)){
		spl<-strsplit(as.character(smapFileName), split = "\\\\")
		lenspll1<-length(spl[[1]])
		spl1 <- strsplit(as.character(spl[[1]][lenspll1]), split = "_")
        # svfamid<-as.character(spl1[[1]][2])
        spl2 <- strsplit(as.character(spl1[[1]][1]), split = "[.]")
        patID <- spl2[[1]][2]
        svfamid <- spl2[[1]][1]
		}else if((length(grep("/",smapFileName))>=1)){
		spl<-strsplit(as.character(smapFileName), split = "/")
		lenspll1<-length(spl[[1]])
		spl1 <- strsplit(as.character(spl[[1]][lenspll1]), split = "_")
        # svfamid<-as.character(spl1[[1]][2])
        spl2 <- strsplit(as.character(spl1[[1]][1]), split = "[.]")
        patID <- spl2[[1]][2]
        svfamid <- spl2[[1]][1]
		}else{
		spl1 <- strsplit(as.character(smapFileName), split = "_")
        # svfamid<-as.character(spl1[[1]][2])
        spl2 <- strsplit(as.character(spl1[[1]][1]), split = "[.]")
        patID <- spl2[[1]][2]
        svfamid <- spl2[[1]][1]
		}
        # conf<-dat$Confidence countfre<-0 percn<-c()
        datf <- c()
		#print(svfamid)
        for (nn in 1:length(rf))
        {
            #### 
			#print(paste("nn:",nn)) 
           #print(variantType2[nn])
			
            if ((variantType2[nn] == "deletion" | variantType2[nn] == "insertion"))
            {
                dat2 <- dat[which((dat$RefStartPos <= rf[nn] & dat$RefStartPos >= 
                  rf_wb_ind[nn] | dat$RefStartPos >= rf[nn] & dat$RefStartPos <= 
                  rf_fb_ind[nn]) & (dat$RefEndPos >= re[nn] & dat$RefEndPos <= 
                  re_wf_ind[nn] | dat$RefEndPos <= re[nn] & dat$RefEndPos >= 
                  re_wb_ind[nn])), ]
                size1 <- size_bn[nn]
                ## Calculating Internal Frequency
                if (nrow(dat2) > 1)
                {
                  countfre <- 0
                  svfam1 <- dat2$SVIdentifier
                  # svind1<-dat2$SVIndex
                  sv1 <- strsplit(as.character(svfam1), split = "_")
                  size_internal <- dat2$Size
                  zygo <- as.character(dat2$Zygosity)
                  type <- as.character(dat2$Type)
                  BSPQI_status_DB <- as.character(dat2$Found_in_self_BSPQI_molecules)
                  BSSSI_status_DB <- as.character(dat2$Found_in_self_BSSSI_molecules)
                  conf <- dat2$Confidence
                  motherZygosity <- c()
                  fatherZygosity <- c()
                  svfamid3 <- c()
                  for (ll in 1:nrow(dat2))
                  {
                    perc <- (size1/size_internal[ll])
                    #### print(perc) print(type[ll])
                    stt <- strsplit(sv1[[ll]][1], split = "[.]")
                    patID1 <- stt[[1]][2]
                    svfamid1 <- stt[[1]][1]
                    #### print(svfamid1)
                    if (perc >= perc_similarity & identical(type[ll], variantType2[nn]) & 
                      (identical(svfamid1, svfamid)) & ((BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "no" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "no") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "-") | (BSPQI_status_DB[ll] == 
                      "-" & BSSSI_status_DB[ll] == "yes")))
                      {
                      # Family Extra column zygosity
                      if (patID == 1 & patID1 == 2)
                      {
                        
                        # svfamid3<-c(svfamid3,svfamid1)
                        motherZygosity <- c(motherZygosity, as.character(zygo[ll]))
                        fatherZygosity <- c(fatherZygosity, "-")
                      } else if (patID == 1 & patID1 == 3)
                      {
                        # svfamid3<-c(svfamid3,as.character(sv1[[ll]][1]))
                        motherZygosity <- c(motherZygosity, "-")
                        fatherZygosity <- c(fatherZygosity, as.character(zygo[ll]))
                      } else if (patID == patID1)
                      {
                        countfre <- NULL
                        motherZygosity <- "-"
                        fatherZygosity <- "-"
                      } else
                      {
                        # svfamid3<-c(svfamid3,svfamid1)
                        
                        motherZygosity <- c(motherZygosity, "-")
                        fatherZygosity <- c(fatherZygosity, "-")
                      }
                    } else if (perc >= perc_similarity & identical(type[ll], 
                      variantType2[nn]) & !(identical(svfamid1, svfamid)) & 
                      (conf[ll] > indelconf) & ((BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "no" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "no") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "-") | (BSPQI_status_DB[ll] == 
                      "-" & BSSSI_status_DB[ll] == "yes")))
                      {
                      countfre <- countfre + 1
                      svfamid3 <- c(svfamid3, as.character(sv1[[ll]][1]))
                      motherZygosity <- c(motherZygosity, "-")
                      fatherZygosity <- c(fatherZygosity, "-")
                    } else
                    {
                      if (!(identical(svfamid1, svfamid)))
                      {
                        countfre <- countfre + 0
                        svfamid3 <- c(svfamid3, as.character(sv1[[ll]][1]))
                      }
                      
                      motherZygosity <- c(motherZygosity, "-")
                      fatherZygosity <- c(fatherZygosity, "-")
                    }
                    
                  }
                  if ((length(svfamid3) >= 1) & length(countfre) >= 1)
                  {
                    dat_temp <- data.frame(svfamid3, countfre)
                    countfre1 <- 0
                    if (nrow(dat_temp) > 0)
                    {
                      #### print(paste('dat_temp',dim(dat_temp)))
                      usvfamid3 <- as.character(unique(svfamid3))
                      
                      for (u in 1:length(usvfamid3))
                      {
                        dat_temp1 <- dat_temp[which(dat_temp$svfamid3 %in% 
                          usvfamid3[u]), ]
                        ct <- sum(dat_temp1$count)
                        if (ct >= 1)
                        {
                          countfre1 <- countfre1 + 1
                        } else
                        {
                          countfre1 <- countfre1 + 0
                        }
                      }
                    } else
                    {
                      countfre1 <- 0
                    }
                  } else
                  {
                    countfre1 <- 0
                  }
                  fatherZygosity <- gsub("-", NA, fatherZygosity)
                  fatherZygosity <- as.character(na.omit(fatherZygosity))
                  if (length(fatherZygosity) > 1)
                  {
                    fatherZygosity <- paste(as.character(fatherZygosity), 
                      collapse = ",")
                  } else if (length(fatherZygosity) == 0)
                  {
                    fatherZygosity <- "-"
                  } else
                  {
                    fatherZygosity <- as.character(fatherZygosity)
                  }
                  
                  motherZygosity <- gsub("-", NA, motherZygosity)
                  motherZygosity <- as.character(na.omit(motherZygosity))
                  if (length(motherZygosity) > 1)
                  {
                    motherZygosity <- paste(as.character(motherZygosity), 
                      collapse = ",")
                  } else if (length(motherZygosity) == 0)
                  {
                    motherZygosity <- "-"
                  } else
                  {
                    motherZygosity <- as.character(motherZygosity)
                  }
                  ##### print(names(datf)[56:58]) print(paste('INSDEL:',countfre1,sep=''))
                  famno <- as.numeric(unname(hash::values(ha, keys = svfamid)))
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = as.numeric(format(((countfre1/(usamp - 
                    famno)) * 100), scientific = FALSE)), motherZygosity = as.character(motherZygosity), 
                    FatherZygosity = as.character(fatherZygosity), stringsAsFactors = FALSE)
                  #### print(dim(data1)) print(dim(data1))
                  #### print(identical(names(data1),names(datf))) print(names(data1)[56:58])
                  datf <- rbind(datf, data1)
                } else if (nrow(dat2) == 1)
                {
                  # dgv_match=TRUE Calculating percentage similarity
                  countfre <- 0
                  conf <- dat2$Confidence
                  size_internal <- dat2$Size
                  BSPQI_status_DB <- as.character(dat2$Found_in_self_BSPQI_molecules)
                  BSSSI_status_DB <- as.character(dat2$Found_in_self_BSSSI_molecules)
                  perc <- (size1/size_internal)
                  svv <- strsplit(as.character(svfam1), split = "_")
                  zygo <- as.character(dat2$Zygosity)
                  stt <- strsplit(svv[[1]][1], split = "[.]")
                  patID1 <- stt[[1]][2]
                  svfamid1 <- stt[[1]][1]
                  motherZygosity <- ""
                  fatherZygosity <- ""
                  
                  type <- as.character(dat2$Type)
                  if (perc >= perc_similarity & identical(type, variantType2[nn]) & 
                    (identical(svfamid1, svfamid)) & ((BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "yes") | (BSPQI_status_DB == 
                    "no" & BSSSI_status_DB == "yes") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "no") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "-") | (BSPQI_status_DB == 
                    "-" & BSSSI_status_DB == "yes")))
                    {
                    # Family Extra column zygosity
                    if (patID == 1 & patID1 == 2)
                    {
                      motherZygosity <- as.character(zygo)
                      fatherZygosity <- "-"
                    } else if (patID == 1 & patID1 == 3)
                    {
                      motherZygosity <- "-"
                      fatherZygosity <- as.character(zygo)
                    } else if (patID == patID1)
                    {
                      motherZygosity <- "-"
                      fatherZygosity <- "-"
                    } else
                    {
                      motherZygosity <- "-"
                      fatherZygosity <- "-"
                    }
                  } else if (perc >= perc_similarity & identical(type, variantType2[nn]) & 
                    !(identical(svfamid1, svfamid)) & ((BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "yes") | (BSPQI_status_DB == 
                    "no" & BSSSI_status_DB == "yes") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "no") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "-") | (BSPQI_status_DB == 
                    "-" & BSSSI_status_DB == "yes")) & conf > indelconf)
                    {
                    countfre <- 1
                    motherZygosity <- "-"
                    fatherZygosity <- "-"
                  } else
                  {
                    countfre <- 0
                    motherZygosity <- "-"
                    fatherZygosity <- "-"
                  }
                  ##### print(paste('INSDEL:',countfre,sep='')) print(names(datf)[56:58])
				  #print(famno)
				  #print(ha)
                  famno <- as.numeric(unname(hash::values(ha, keys = svfamid)))
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = as.numeric(format(((countfre/(usamp - 
                    famno)) * 100), scientific = FALSE)), motherZygosity = as.character(motherZygosity), 
                    FatherZygosity = as.character(fatherZygosity), stringsAsFactors = FALSE)
                  #### print(dim(data1)) print(names(data1)[56:58])
                  #### print(identical(names(data1),names(datf))) print(names(data1))
                  datf <- rbind(datf, data1)
                } else
                {
                  # dgv_match=FALSE
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = "-", 
                    motherZygosity = "-", FatherZygosity = "-", stringsAsFactors = FALSE)
                  #### print(dim(data1)) print(names(data1)[56:58])
                  #### print(names(datf)[56:58])
                  #### print(identical((names(data1)[56]),(names(datf)[56])))
                  #### print(identical((names(data1)[57]),(names(datf)[57])))
                  #### print(identical((names(data1)[58]),(names(datf)[58])))
                  datf <- rbind(datf, data1)
                  # next;
                }
                
            } else if ((length(grep("inversion", variantType2[nn])) >= 1) | 
                (length(grep("translocation", variantType2[nn])) >= 1))
                {
                dat2 <- dat[which((dat$start <= rf[nn] & dat$start >= rf_wb_int[nn] | 
                  dat$start >= rf[nn] & dat$start <= rf_fb_int[nn]) & (dat$end >= 
                  re[nn] & dat$end <= re_fb_int[nn] | dat$end <= re[nn] & 
                  dat$end >= re_wb_int[nn])), ]
                size1 <- size_bn[nn]
                ## Writing if the dgv_match is TRUE or not
                countfre <- c()
                if (nrow(dat2) > 1)
                {
                  countfre <- 0
                  svfam1 <- dat2$SVIdentifier
                  # svind1<-dat2$SVIndex
                  sv1 <- strsplit(as.character(svfam1), split = "_")
                  size_internal <- dat2$Size
                  zygo <- as.character(dat2$Zygosity)
                  type <- as.character(dat2$Type)
                  BSPQI_status_DB <- as.character(dat2$Found_in_self_BSPQI_molecules)
                  BSSSI_status_DB <- as.character(dat2$Found_in_self_BSSSI_molecules)
                  BSPQI_chimeric_score_DB <- as.character(dat2$Fail_BSPQI_assembly_chimeric_score)
                  BSSSI_chimeric_score_DB <- as.character(dat2$Fail_BSSSI_assembly_chimeric_score)
                  conf <- dat2$Confidence
                  motherZygosity <- c()
                  fatherZygosity <- c()
                  svfamid3 <- c()
                  
                  for (ll in 1:nrow(dat2))
                  {
                    perc <- (size1/size_internal[ll])
                    stt <- strsplit(sv1[[ll]][1], split = "[.]")
                    patID1 <- stt[[1]][2]
                    svfamid1 <- stt[[1]][1]
                    if (perc >= perc_similarity & identical(type[ll], variantType2[nn]) & 
                      (identical(svfamid1, svfamid)) & ((BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "no" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "no") | (BSPQI_status_DB[ll] == 
                      "yes" & BSSSI_status_DB[ll] == "-") | (BSPQI_status_DB[ll] == 
                      "-" & BSSSI_status_DB[ll] == "yes")) & ((BSPQI_chimeric_score_DB[ll] == 
                      "pass" & BSSSI_chimeric_score_DB[ll] == "pass") | 
                      (BSPQI_chimeric_score_DB[ll] == "fail" & BSSSI_chimeric_score_DB[ll] == 
                        "pass") | (BSPQI_chimeric_score_DB[ll] == "pass" & 
                      BSSSI_chimeric_score_DB[ll] == "fail") | (BSPQI_chimeric_score_DB[ll] == 
                      "pass" & BSSSI_chimeric_score_DB[ll] == "-") | (BSPQI_chimeric_score_DB[ll] == 
                      "-" & BSSSI_chimeric_score_DB[ll] == "pass")))
                      {
                      # Family Extra column zygosity
                      if (patID == 1 & patID1 == 2)
                      {
                        motherZygosity <- c(motherZygosity, as.character(zygo[ll]))
                        fatherZygosity <- c(fatherZygosity, "-")
                      } else if (patID == 1 & patID1 == 3)
                      {
                        
                        motherZygosity <- c(motherZygosity, "-")
                        fatherZygosity <- c(fatherZygosity, as.character(zygo[ll]))
                      } else if (patID == patID1)
                      {
                        
                        motherZygosity <- "-"
                        fatherZygosity <- "-"
                      } else
                      {
                        countfre <- NULL
                        motherZygosity <- c(motherZygosity, "-")
                        fatherZygosity <- c(fatherZygosity, "-")
                      }
                    } else if (perc >= perc_similarity & identical(type[ll], 
                      variantType2[nn]) & !(identical(svfamid1, svfamid)) & 
                      ((BSPQI_status_DB[ll] == "yes" & BSSSI_status_DB[ll] == 
                        "yes") | (BSPQI_status_DB[ll] == "no" & BSSSI_status_DB[ll] == 
                        "yes") | (BSPQI_status_DB[ll] == "yes" & BSSSI_status_DB[ll] == 
                        "no") | (BSPQI_status_DB[ll] == "yes" & BSSSI_status_DB[ll] == 
                        "-") | (BSPQI_status_DB[ll] == "-" & BSSSI_status_DB[ll] == 
                        "yes")) & ((identical(type[ll], "inversion") & 
                      conf[ll] > invconf) | (identical(type[ll], "translocation") & 
                      conf[ll] > transconf)) & ((BSPQI_chimeric_score_DB[ll] == 
                      "pass" & BSSSI_chimeric_score_DB[ll] == "pass") | 
                      (BSPQI_chimeric_score_DB[ll] == "fail" & BSSSI_chimeric_score_DB[ll] == 
                        "pass") | (BSPQI_chimeric_score_DB[ll] == "pass" & 
                      BSSSI_chimeric_score_DB[ll] == "fail") | (BSPQI_chimeric_score_DB[ll] == 
                      "pass" & BSSSI_chimeric_score_DB[ll] == "-") | (BSPQI_chimeric_score_DB[ll] == 
                      "-" & BSSSI_chimeric_score_DB[ll] == "pass")))
                      {
                      countfre <- countfre + 1
                      svfamid3 <- c(svfamid3, as.character(sv1[[ll]][1]))
                      motherZygosity <- c(motherZygosity, "-")
                      fatherZygosity <- c(fatherZygosity, "-")
                    } else
                    {
                      # countfre=countfre+0
                      if (!(identical(svfamid1, svfamid)))
                      {
                        countfre <- countfre + 0
                        svfamid3 <- c(svfamid3, as.character(sv1[[ll]][1]))
                      }
                      motherZygosity <- c(motherZygosity, "-")
                      fatherZygosity <- c(fatherZygosity, "-")
                    }
                    
                  }
                  if ((length(svfamid3) >= 1) & length(countfre) >= 1)
                  {
                    dat_temp <- data.frame(svfamid3, countfre)
                    countfre1 <- 0
                    if (nrow(dat_temp) > 0)
                    {
                      #### print(paste('dat_temp',dim(dat_temp)))
                      usvfamid3 <- as.character(unique(svfamid3))
                      
                      for (u in 1:length(usvfamid3))
                      {
                        dat_temp1 <- dat_temp[which(dat_temp$svfamid3 %in% 
                          usvfamid3[u]), ]
                        ct <- sum(dat_temp1$count)
                        if (ct >= 1)
                        {
                          countfre1 <- countfre1 + 1
                        } else
                        {
                          countfre1 <- countfre1 + 0
                        }
                      }
                    } else
                    {
                      countfre1 <- 0
                    }
                  } else
                  {
                    countfre1 <- 0
                  }
                  
                  fatherZygosity <- gsub("-", NA, fatherZygosity)
                  fatherZygosity <- as.character(unique(na.omit(fatherZygosity)))
                  if (length(fatherZygosity) > 1)
                  {
                    fatherZygosity <- paste(as.character(fatherZygosity), 
                      collapse = ",")
                  } else if (length(fatherZygosity) == 0)
                  {
                    fatherZygosity <- "-"
                  } else
                  {
                    fatherZygosity <- as.character(fatherZygosity)
                  }
                  
                  motherZygosity <- gsub("-", NA, motherZygosity)
                  motherZygosity <- as.character(unique(na.omit(motherZygosity)))
                  if (length(motherZygosity) > 1)
                  {
                    motherZygosity <- paste(as.character(motherZygosity), 
                      collapse = ",")
                  } else if (length(motherZygosity) == 0)
                  {
                    motherZygosity <- "-"
                  } else
                  {
                    motherZygosity <- as.character(motherZygosity)
                  }
                  ##### print(paste('INVTRANS:',countfre,sep=''))
                  famno <- as.numeric(unname(hash::values(ha, keys = svfamid)))
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = as.numeric(format(((countfre1/(usamp - 
                    famno)) * 100), scientific = FALSE)), motherZygosity = as.character(motherZygosity), 
                    FatherZygosity = as.character(fatherZygosity), stringsAsFactors = FALSE)
                  #### print(dim(data1))
                  datf <- rbind(datf, data1)
                } else if (nrow(dat2) == 1)
                {
                  ## dgv_match=TRUE Calculating percentage similarity
                  countfre
                  size_internal <- dat2$Size
                  perc <- (size1/size_internal)
                  svv <- strsplit(as.character(svfam1), split = "_")
                  zygo <- as.character(dat2$Zygosity)
                  stt <- strsplit(svv[[1]][1], split = "[.]")
                  type <- as.character(dat2$Type)
                  patID1 <- stt[[1]][2]
                  svfamid1 <- stt[[1]][1]
                  conf <- dat2$Confidence
                  BSPQI_status_DB <- as.character(dat2$Found_in_self_BSPQI_molecules)
                  BSSSI_status_DB <- as.character(dat2$Found_in_self_BSSSI_molecules)
                  BSPQI_chimeric_score_DB <- as.character(dat2$Fail_BSPQI_assembly_chimeric_score)
                  BSSSI_chimeric_score_DB <- as.character(dat2$Fail_BSSSI_assembly_chimeric_score)
                  if (perc >= perc_similarity & identical(type[ll], variantType2[nn]) & 
                    (identical(svfamid1, svfamid)) & ((BSPQI_status_DB[ll] == 
                    "yes" & BSSSI_status_DB[ll] == "yes") | (BSPQI_status_DB == 
                    "no" & BSSSI_status_DB == "yes") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "no") | (BSPQI_status_DB == 
                    "yes" & BSSSI_status_DB == "-") | (BSPQI_status_DB == 
                    "-" & BSSSI_status_DB == "yes")) & ((BSPQI_chimeric_score_DB == 
                    "pass" & BSSSI_chimeric_score_DB == "pass") | (BSPQI_chimeric_score_DB == 
                    "fail" & BSSSI_chimeric_score_DB == "pass") | (BSPQI_chimeric_score_DB == 
                    "pass" & BSSSI_chimeric_score_DB == "fail") | (BSPQI_chimeric_score_DB == 
                    "pass" & BSSSI_chimeric_score_DB == "-") | (BSPQI_chimeric_score_DB == 
                    "-" & BSSSI_chimeric_score_DB == "pass")))
                    {
                    # Family Extra column zygosity
                    if (patID == 1 & patID1 == 2)
                    {
                      countfre <- countfre + 0
                      motherZygosity <- as.character(zygo)
                      fatherZygosity <- "-"
                    } else if (patID == 1 & patID1 == 3)
                    {
                      countfre <- countfre + 0
                      motherZygosity <- "-"
                      fatherZygosity <- as.character(zygo)
                    } else if (patID == patID1)
                    {
                      countfre <- countfre + 0
                      motherZygosity <- "-"
                      fatherZygosity <- "-"
                    } else
                    {
                      countfre <- countfre + 1
                      motherZygosity <- "-"
                      fatherZygosity <- "-"
                    }
                  } else if (perc >= perc_similarity & identical(type[ll], 
                    variantType2[nn]) & !(identical(svfamid1, svfamid)) & 
                    ((BSPQI_status_DB == "yes" & BSSSI_status_DB == "yes") | 
                      (BSPQI_status_DB == "no" & BSSSI_status_DB == "yes") | 
                      (BSPQI_status_DB == "yes" & BSSSI_status_DB == "no") | 
                      (BSPQI_status_DB == "yes" & BSSSI_status_DB == "-") | 
                      (BSPQI_status_DB == "-" & BSSSI_status_DB == "yes")) & 
                    ((identical(type, "inversion") & conf > invconf) | 
                      (identical(type, "translocation") & conf > transconf)) & 
                    ((BSPQI_chimeric_score_DB == "pass" & BSSSI_chimeric_score_DB == 
                      "pass") | (BSPQI_chimeric_score_DB == "fail" & BSSSI_chimeric_score_DB == 
                      "pass") | (BSPQI_chimeric_score_DB == "pass" & BSSSI_chimeric_score_DB == 
                      "fail") | (BSPQI_chimeric_score_DB == "pass" & BSSSI_chimeric_score_DB == 
                      "-") | (BSPQI_chimeric_score_DB == "-" & BSSSI_chimeric_score_DB == 
                      "pass")))
                      {
                    countfre <- countfre + 1
                    motherZygosity <- "-"
                    fatherZygosity <- "-"
                  } else
                  {
                    countfre <- countfre + 0
                    motherZygosity <- "-"
                    fatherZygosity <- "-"
                  }
                  ##### print(paste('INVTRANS:',countfre,sep=''))
                  famno <- as.numeric(unname(hash::values(ha, keys = svfamid)))
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = as.numeric(format(((countfre1/(usamp - 
                    famno)) * 100), scientific = FALSE)), motherZygosity = as.character(motherZygosity), 
                    FatherZygosity = as.character(fatherZygosity), stringsAsFactors = FALSE)
                  
                  #### print(dim(data1))
                  datf <- rbind(datf, data1)
                } else
                {
                  # dgv_match=FALSE print(paste('QueryData:',dim(dat1[nn,]),sep=''))
                  data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = "-", 
                    motherZygosity = "-", FatherZygosity = "-", stringsAsFactors = FALSE)
                  #### print(dim(data1))
                  datf <- rbind(datf, data1)
                  # next;
                }
                
            } else
            {
                #### print(paste('QueryData:',dim(dat1[nn,]),sep=''))
                
                data1 <- data.frame(dat1[nn, ], Internal_Freq_Perc = "-", 
                  motherZygosity = "-", FatherZygosity = "-", stringsAsFactors = FALSE)
                #### print(dim(data1))
                datf <- rbind(datf, data1)
            }
            
        }
        dataFinal <- rbind(dataFinal, datf)
    }
	if(returnMethod=="Text"){
    st1 <- strsplit(smapFileName, ".txt")
    fname <- st1[[1]][1]
    row.names(dataFinal) <- c()
	filenam<-paste(fname,"_Int.txt",sep="")
    write.table(dataFinal, file.path(smappath, fname), sep = "\t", 
	            row.names = FALSE)
	}
	else if (returnMethod=="dataFrame"){
	return(dataFinal)
	}
	else{
	stop("returnMethod Incorrect")
	}
}