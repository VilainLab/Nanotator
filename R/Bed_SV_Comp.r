#' Reads Bionano Bedfiles
#'
#' @param BNFile  character. Path to Bionano Bed File.
#' @return Data Frame Contains the gene information.
#' @examples
#' \dontrun{
#' }
#' @export
readBNBedFiles <- function(BNFile) {
    ## Reading the Bed File con<-file(BNFile,'r') r10<-readLines(con,n=-1)
    ## close(con) Converting the data to data frame
    ## dat4<-textConnection(r10)
    ## r12<-read.table(dat4,sep='\t',header=FALSE) Extracting data
    r12 <- read.table(BNFile, header = TRUE)
    chrom <- r12[, 1]
    chromstart <- r12[, 2]
    chromend <- r12[, 3]
    gene <- as.character(r12[, 4])
    strand <- as.character(r12[, 5])
    ## Combining the data to form a data frame
    dat1 <- data.frame(Chromosome = chrom, 
	    Chromosome_Start = chromstart, Chromosome_End = chromend, 
		Gene = gene, Strand = strand)
    return(dat1)
}

#' Reads BED files to produce bionano Bed files 
#'
#' @param bedFile  character. Path to UCSC Bed File.
#' @param outdir  character. Path to output directory.
#' @return Data Frame or text file. Contains the gene information.
#' @examples
#' \dontrun{
#' bedFile = "C:\\Annotator\\Data\\Homo_sapiens.Hg19.bed"
#' buildrunBNBedFiles(bedFile,outdir=tempdir())
#' }
#' @export
buildrunBNBedFiles <- function(bedFile,returnMethod=c("Text","dataFrame"),
    outdir) {
    ## Reading the Bed File
    con <- file(bedFile, "r")
    r10 <- readLines(con, n = -1)
    close(con)
    ## Converting the data to data frame
    dat4 <- textConnection(r10)
    r12 <- read.table(dat4, sep = "\t", header = FALSE)
    ## Extracting data
	print(dim(r12))
    chrom <- stringr::str_trim(r12[,1])
    chromstart <- stringr::str_trim(r12[,3])
    chromend <- stringr::str_trim(r12[,4])
    gene <- stringr::str_trim(as.character(r12[,5]))
    strand <- stringr::str_trim(as.character(r12[,6]))
    ## Changing the chromosome Start Name
    chrom1 <- gsub("chr", "", x = chrom)
    ## Male and Female chromosome association
    if (length(grep("X", chrom1)) > 1 & length(grep("Y", chrom1)) > 1) {
        chrom1 <- gsub("X", 23, chrom1)
        chrom1 <- gsub("Y", 24, chrom1)
    } else if (length(grep("X", chrom1)) > 1) {
        chrom1 <- gsub("X", 23, chrom1)
    } else {
        print("Genome doesnot have any Sex Chromosome")
    }
    ## Combining the data to form a data frame
    dat1 <- data.frame(Chromosome = as.character(chrom1), Chromosome_Start = as.numeric(chromstart), 
        Chromosome_End = as.numeric(chromend), Gene = as.character(gene), Strand = as.character(strand))
    ## writing Bionano Bedfiles
	if(returnMethod=="Text"){
    if (length(grep("\\\\", bedFile)) >= 1) {
        st <- strsplit(bedFile, split = "\\\\")
        fname <- st[[1]][4]
        st1 <- strsplit(fname, split = ".bed")
        fname1 <- paste(st1[[1]][1], "_BN.bed", sep = "")
    } else {
        fname <- bedFile
        st1 <- strsplit(fname, split = ".bed")
        fname1 <- paste(st1[[1]][1], "_BN.bed", sep = "")
    }
    write.table(dat1, paste(outdir, "/", fname1, sep = ""))
	}
	else if (returnMethod=="dataFrame"){
    return(dat1)
	}
	else {
	stop("Method of Return improper")
	}
}
#' Reads SMAP files to extract information 
#'
#' @param smap  character. Path to SMAP file.
#' @return Data Frame or text file. Contains the SMAP information.
#' @examples
#' \dontrun{
#' smap = "C:\\Annotator\\Data\\F1_UDN287643_P_Q.S_VAP_SVmerge_trio.txt"
#' readSMap(smap)
#' }
#' @export
readSMap <- function(smap) {
    ## reading the smap text file
    con <- file(smap, "r")
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
    return(r1)
}
#' Calculates Genes that overlap the SV region
#'
#' @param bed  Text Bionano Bed file.
#' @param chrom  character SVmap chromosome.
#' @param startpos  numeric starting position of the breakpoints.
#' @param endpos  numeric end position of the breakpoints.
#' @param svid  numeric Structural variant identifier (Bionano generated).
#' @return Data Frame. Contains the SVID,Gene name,strand information and 
#' percentage of SV covered.
#' @examples
#' \dontrun{
#' smap="C:\\Annotator\\Data\\F1.1_UDN287643_P_Q.S_VAP_SVmerge_trio_original.txt"
#' bedFile = "C:\\Annotator\\Data\\Homo_sapiens.GRCH19.bed"
#' bed<-buildrunBNBedFiles(bedFile,returnMethod = "dataFrame")
#' smap<-readSMap(smap)
#' chrom<-smap$RefcontigID1
#' startpos<-smap$RefStartPos
#' endpos<-smap$RefEndPos
#' svid<-smap$SVIndex
#' overlapGenes(bed, chrom, startpos, endpos, svid)
#' }
#' @export
overlapGenes <- function(bed, chrom, startpos, endpos, svid) {
    ##Initialising data
    data1 <- data.frame()
    gnsInf <- c()
    SVID <- c()
	##Getting the midpoint of the geme
    #bed$geneMid <- ceiling(bed$Chromosome_Start + ((bed$Chromosome_End - 
        #bed$Chromosome_Start)/2))
    ## Detecting Genes present between the SV breakpoints and Calculating the 
	## percentage coverage of genes across the breakpoints per chromosome.
    for (ii in 1:length(chrom)) {
	    #Checking for genes in the breakpoint
        dat11 <- bed[which(as.numeric(bed$Chromosome) == chrom[ii] & ((bed$Chromosome_Start >= 
            startpos[ii] & bed$Chromosome_End <= endpos[ii]) | (bed$Chromosome_End >= 
            startpos[ii] & bed$Chromosome_Start < startpos[ii]) | (bed$Chromosome_Start >= 
            startpos[ii] & bed$Chromosome_End < startpos[ii]) | (bed$Chromosome_Start <= 
            endpos[ii] & bed$Chromosome_End > endpos[ii]) | (bed$Chromosome_End <= 
            endpos[ii] & bed$Chromosome_Start > endpos[ii]) | ((bed$Chromosome_Start < 
            startpos[ii] & bed$Chromosome_End > endpos[ii])) | ((bed$Chromosome_End < 
            startpos[ii] & bed$Chromosome_Start > endpos[ii])))), ]
	    ##Extracting strand and calculating  percentage coverage information for a gene
		##covering the breakpoints if multiple genes are found in the breakpoint region.
        if (nrow(dat11) > 1) {
			##Extracting strand and chromosome start information
            chromos <- dat11$Chromosome
            chromStart <- dat11$Chromosome_Start
            chromEnd <- dat11$Chromosome_End
            gen1 <- dat11$Gene
            strnd <- dat11$Strand
            genMid <- dat11$geneMid
            geneInfo <- c()
			##Calculating the coverage of the gene
            for (k in 1:length(gen1)) {
                          
				lengthgene<-chromStart[k]-chromEnd[k]
				lengthbp<-startpos[ii]-endpos[ii]
                # print(paste('distfromStart:',distfromStart),sep='')
                # print(paste('distfromEnd:',distfromEnd),sep='') Checking for
                # partial/complete inclusion in the SV
                if ((chromStart[k] >= startpos[ii] & 
					chromEnd[k] <= endpos[ii])) {
                  percentage = 100
                } 
				else if(((chromStart[k] < startpos[ii] & 
					chromEnd[k] > endpos[ii]) | (chromEnd[k]< startpos[ii] & 
					chromStart[k]> endpos[ii]))& (lengthgene > lengthbp)) {
					percentage=round(abs(((startpos[ii]-endpos[ii])/
					    (chromStart[k]-chromEnd[ii]))*100),digits=2)
					}				
				else if (((chromStart[k] < startpos[ii] ) & (chromEnd[k]< endpos[ii])) | 
				    (chromStart[k] < endpos[ii] ) & (chromEnd[k]< startpos[ii])) {
					distfromStart <- chromStart[k] - startpos[ii]
                  percentage = round(abs((distfromStart/(chromEnd[k] - chromStart[k])) * 
                    100),digits=2)
                }
				else if (((chromStart[k] > startpos[ii] ) & (chromEnd[k] > endpos[ii])) | 
				    (chromStart[k] > endpos[ii] ) & (chromEnd[k] > startpos[ii])) {
				  distfromEnd <- endpos[ii] - chromEnd[k]
                  percentage = round(abs((distfromEnd/(chromEnd[k] - chromStart[k])) * 
                    100),digits=2)	
                }					
				else {
                  percentage = "NA"
                }
                geneInfo <- c(geneInfo, paste(gen1[k], "(", strnd[k], ":", 
                  percentage, ")", sep = ""))
            }
            geneInfo1 <- paste(geneInfo, collapse = ";")
            gnsInf <- c(gnsInf, geneInfo1)
            SVID <- c(SVID, svid[ii])
        } ##Extract strand information and calculate coverage if a single
		  ## gene is extracted.
		else if (nrow(dat11) == 1) {
            chromos <- dat11$Chromosome
            chromStart <- dat11$Chromosome_Start
            chromEnd <- dat11$Chromosome_End
            gen1 <- dat11$Gene
            strnd <- dat11$Strand
            genMid <- dat11$geneMid
            geneInfo <- c()
            distfromStart <- startpos[ii] - chromStart
            distfromEnd <- endpos[ii] - chromEnd
			lengthgene<-abs(chromStart-chromEnd)
			lengthbp<-abs(startpos[ii]-endpos[ii])
            ## Checking for partial/complete inclusion in the SV
            if (distfromStart <= 0 & distfromEnd >= 0 ) {
                percentage = 100
            }
            else if(((chromStart < startpos[ii] & 
					chromEnd > endpos[ii]) | (chromEnd< startpos[ii] & 
					chromStart> endpos[ii]))& (lengthgene > lengthbp)) {
					percentage=round(abs(((startpos[ii]-endpos[ii])/
					    (chromStart-chromEnd))*100),digits=2)
					}			
			else if ((distfromStart < 0 & distfromEnd >= 0) | (distfromStart < 
                0 & distfromEnd <= 0)) {
                percentage = round(abs((distfromStart/(chromEnd - chromStart)) * 
                  100),digits=2)
            } else if ((distfromEnd >= 0 & distfromStart <= 0) | (distfromStart < 
                0 & distfromEnd <= 0)) {
                percentage = round(abs((distfromEnd/(chromEnd - chromStart)) * 
                  100),digits=2)
            } else {
                percentage = "NA"
            }
            geneInfo1 <- c(geneInfo, paste(gen1, "(", strnd, ":", percentage, 
                ")", sep = ""))
            gnsInf <- c(gnsInf, geneInfo1)
            SVID <- c(SVID, svid[ii])
        } else {
            SVID <- c(SVID, svid[ii])
            gnsInf <- c(gnsInf, "")
        }
    }
	##Writing a returning a data frame with gene information and SVID
	dat3 <- data.frame(SVID, OverlapGenes_strand_bases = gnsInf)
    return(dat3)
}
#' Calculates Genes that are near to the SV region
#'
#' @param bed  Text Bionano Bed file.
#' @param chrom  character SVmap chromosome.
#' @param startpos  numeric starting position of the breakpoints.
#' @param endpos  numeric end position of the breakpoints.
#' @param svid  numeric Structural variant identifier (Bionano generated).
#' @param n  numeric Number of genes to report which are nearest to the breakpoint.
#' Default is  	3.
#' @return Data Frame. Contains the SVID,Gene name,strand information and 
#' Distance from the SV covered.
#' @examples
#' \dontrun{
#' smap="C:\\Annotator\\Data\\F1.1_UDN287643_P_Q.S_VAP_SVmerge_trio_original.txt"
#' bedFile = "C:\\Annotator\\Data\\Homo_sapiens.GRCH19.bed"
#' bed<-buildrunBNBedFiles(bedFile,returnMethod = "dataFrame")
#' smap<-readSMap(smap)
#' chrom<-smap$RefcontigID1
#' startpos<-smap$RefStartPos
#' endpos<-smap$RefEndPos
#' svid<-smap$SVIndex
#' n<-3
#' nonOverlapGenes(bed, chrom, startpos, endpos, svid,n)
#' }
#' @export
nonOverlapGenes <- function(bed, chrom, startpos, endpos, svid, SVTyp, 
    n = 3) {
	##Initializing data
    data1 <- data.frame()
    gnsInf_UP <- c()
    gnsInf_DN <- c()
    SVID <- c()
	##Extracting genes near the breakpoints and calculating distance from it.
    for (ii in 1:length(chrom)) {
        #print(paste('ii:',ii,sep=''))
        datup <- bed[which((as.character(bed$Chromosome) == chrom[ii]) & 
            ((bed$Chromosome_Start < startpos[ii] & bed$Chromosome_End < 
                endpos[ii]) |(bed$Chromosome_End < startpos[ii] & bed$Chromosome_Start < 
                endpos[ii]))), ]
        #datup_minus <- bed[which(as.character(bed$Chromosome) == chrom[ii] & 
         #   ((bed$Chromosome_End < startpos[ii] & bed$Chromosome_Start < 
          #      endpos[ii])) & bed$Strand == "-"), ]
        datdn <- bed[which((as.character(bed$Chromosome) == chrom[ii]) & 
            ((bed$Chromosome_Start > endpos[ii] & bed$Chromosome_End > 
                startpos[ii]) |(bed$Chromosome_End > endpos[ii] & bed$Chromosome_Start > 
                startpos[ii]))), ]
        #datdn_minus <- bed[which(as.character(bed$Chromosome) == chrom[ii] & 
         #   ((bed$Chromosome_End > endpos[ii] & bed$Chromosome_Start > 
          #      startpos[ii])) & bed$Strand == "-"), ]
        #print(datup);print(datdn)
		if(nrow(datup)>0 & nrow(datdn)>0){
		##Upstream Genes
		for(ll in 1:length(datup$Chromosome)){
		diffStartGene_startbp=startpos[ii]-datup$Chromosome_Start[ll]
		diffEndGene_startbp=endpos[ii]-datup$Chromosome_Start[ll]
		diffStartGene_endbp=startpos[ii]-datup$Chromosome_End[ll]
		diffEndGene_endbp=endpos[ii]-datup$Chromosome_End[ll]
		if((datup$Chromosome_Start[ll] < startpos[ii] 
		    & datup$Chromosome_End[ll] < endpos[ii])&
		    (diffStartGene_startbp > 0 & diffEndGene_startbp > 0) &
			(diffStartGene_startbp < diffStartGene_endbp)){
        datup$diff_up[ll] <- abs(startpos[ii] - datup$Chromosome_Start[ll])
		}
		else if ((datup$Chromosome_Start[ll] < startpos[ii] 
				& datup$Chromosome_End[ll] < endpos[ii])&
				(diffStartGene_startbp > 0 & diffEndGene_startbp > 0) &
			    (diffStartGene_startbp > diffStartGene_endbp)) {
			    datup$diff_up[ll] <- abs(startpos[ii] - datup$Chromosome_End[ll])
			}
		else{
		    datup$diff_up[ll]<-0
			}
		}
		dat_up <- datup[order(datup$diff_up),]
		dat_up<-dat_up[which(dat_up$diff_up > 0),]
		genes_up<- dat_up$Gene[1:n]
        strands_up <- dat_up$Strand[1:n]
		diff_up<-dat_up$diff_up[1:n]
        genesUP <- c()
        ### Storing the gene, strand and distance information in vectors
        for (k in 1:n) {
		    pas <- paste(genes_up[k], "(", strands_up[k], 
                ":", diff_up[k], ")", sep = "")
            genesUP <- c(genesUP, pas)
			
        }
        genesUP1 <- paste(genesUP, collapse = ";")
        gnsInf_UP <- c(gnsInf_UP, as.character(genesUP1))
		#Downstram Genes
		for(kk in 1:length(datdn$Chromosome)){
		diffStartGene_startbp=startpos[ii]-datdn$Chromosome_Start[kk]
		diffEndGene_startbp=endpos[ii]-datdn$Chromosome_Start[kk]
		diffStartGene_endbp=startpos[ii]-datdn$Chromosome_End[kk]
		diffEndGene_endbp=endpos[ii]-datdn$Chromosome_End[kk]
		if((datdn$Chromosome_Start[kk] > startpos[ii] 
		    & datdn$Chromosome_End[kk] > endpos[ii])&
		    (diffStartGene_startbp < 0 & diffEndGene_startbp < 0) &
			(diffEndGene_startbp > diffEndGene_endbp)) {			
            datdn$diff_dn[kk] <- abs(endpos[ii] - datdn$Chromosome_Start[kk])
			}
		else if ((datdn$Chromosome_Start[kk] > startpos[ii] 
		    & datdn$Chromosome_End[kk] > endpos[ii])&
		    (diffStartGene_startbp < 0 & diffEndGene_startbp < 0) &
			(diffEndGene_startbp < diffEndGene_endbp)){
        datdn$diff_dn <- abs(endpos[ii] - datdn$Chromosome_End[kk])
		}
		else{
		    datdn$diff_dn[kk]<-0
			}
		}
		dat_dn <- datdn[order(datdn$diff_dn), ]
		dat_dn<-dat_dn[which(dat_dn$diff_dn > 0),]
		genes_dn <- dat_dn$Gene[1:n]
        strands_dn <- dat_dn$Strand[1:n]
		diff_dn<-dat_dn$diff_dn[1:n]
        genesDN <- c()
        ### Storing the gene, strand and distance information in vectors
        for (k in 1:n) {
		    
            pas <- paste(genes_dn[k], "(", strands_dn[k], 
                ":", diff_dn[k], ")", sep = "")
            genesDN <- c(genesDN, pas)
			
        }
        genesDN1 <- paste(genesDN, collapse = ";")
        gnsInf_DN <- c(gnsInf_DN, as.character(genesDN1))
		}
		else if (nrow(datup)==0 & nrow(datdn)>0){
		gnsInf_UP <- c(gnsInf_UP, "-")
		for(kk in 1:length(datdn$Chromosome)){
		diffStartGene_startbp=startpos[ii]-datdn$Chromosome_Start[kk]
		diffEndGene_startbp=endpos[ii]-datdn$Chromosome_Start[kk]
		diffStartGene_endbp=startpos[ii]-datdn$Chromosome_End[kk]
		diffEndGene_endbp=endpos[ii]-datdn$Chromosome_End[kk]
		if((datdn$Chromosome_Start[kk] > startpos[ii] 
		    & datdn$Chromosome_End[kk] > endpos[ii])&
		    (diffStartGene_startbp < 0 & diffEndGene_startbp < 0) &
			(diffEndGene_startbp > diffEndGene_endbp)) {			
            datdn$diff_dn[kk] <- abs(endpos[ii] - datdn$Chromosome_Start[kk])
			}
		else if ((datdn$Chromosome_Start[kk] > startpos[ii] 
		    & datdn$Chromosome_End[kk] > endpos[ii])&
		    (diffStartGene_startbp < 0 & diffEndGene_startbp < 0) &
			(diffEndGene_startbp < diffEndGene_endbp)){
        datdn$diff_dn <- abs(endpos[ii] - datdn$Chromosome_End[kk])
		}
		else{
		    datdn$diff_dn[kk]<-0
			}
		}
		dat_dn <- datdn[order(datdn$diff_dn), ]
		dat_dn<-dat_dn[which(dat_dn$diff_dn > 0),]
		 genes_dn <- dat_dn$Gene[1:n]
        strands_dn <- dat_dn$Strand[1:n]
		diff_dn<-dat_dn$diff_dn[1:n]
        genesDN <- c()
        ### Storing the gene, strand and distance information in vectors
        for (k in 1:n) {
		     pas <- paste(genes_dn[k], "(", strands_dn[k], 
                ":", diff_dn[k], ")", sep = "")
            genesDN <- c(genesDN, pas)
			
        }
        genesDN1 <- paste(genesDN, collapse = ";")
        gnsInf_DN <- c(gnsInf_DN, as.character(genesDN1))
		}
		else if (nrow(datup)>0 & nrow(datdn)==0){
		for(ll in 1:length(datup$Chromosome)){
		diffStartGene_startbp=startpos[ii]-datup$Chromosome_Start[ll]
		diffEndGene_startbp=endpos[ii]-datup$Chromosome_Start[ll]
		diffStartGene_endbp=startpos[ii]-datup$Chromosome_End[ll]
		diffEndGene_endbp=endpos[ii]-datup$Chromosome_End[ll]
		if((datup$Chromosome_Start[ll] < startpos[ii] 
		    & datup$Chromosome_End[ll] < endpos[ii])&
		    (diffStartGene_startbp > 0 & diffEndGene_startbp > 0) &
			(diffStartGene_startbp < diffStartGene_endbp)){
        datup$diff_up[ll] <- abs(startpos[ii] - datup$Chromosome_Start[ll])
		}
		else if ((datup$Chromosome_Start[ll] < startpos[ii] 
				& datup$Chromosome_End[ll] < endpos[ii])&
				(diffStartGene_startbp > 0 & diffEndGene_startbp > 0) &
			    (diffStartGene_startbp > diffStartGene_endbp)) {
			    datup$diff_up[ll] <- abs(startpos[ii] - datup$Chromosome_End[ll])
			}
		else{
		    datup$diff_up[ll]<-0
			}
		}
		dat_up <- datup[order(datup$diff_up),]
		dat_up<-dat_up[which(dat_up$diff_up > 0),]
		genes_up<- dat_up$Gene[1:n]
        strands_up <- dat_up$Strand[1:n]
		diff_up<-dat_up$diff_up[1:n]
        genesUP <- c()
        ### Storing the gene, strand and distance information in vectors
        for (k in 1:n) {
		    pas <- paste(genes_up[k], "(", strands_up[k], 
                ":", diff_up[k], ")", sep = "")
            genesUP <- c(genesUP, pas)
			
        }
        genesUP1 <- paste(genesUP, collapse = ";")
        gnsInf_UP <- c(gnsInf_UP, as.character(genesUP1))
		gnsInf_DN <- c(gnsInf_DN, "-")
		}
		else{
		gnsInf_UP <- c(gnsInf_UP, "-")
		gnsInf_DN <- c(gnsInf_DN, "-")
		}
		
        ## Upstream genes
        
        ## Downstream Genes
        
        ## Getting the genes and strand data
        
        ### Genes_Up_minusEnd
        ## Getting Down streamplus genes
       
        ## Getting Genes minus Downstream
        SVID <- c(SVID, svid[ii])
    }
	##Writing and storing the data
    dat4 <- data.frame(SVID, Upstream_nonOverlapGenes_strand_bases = gnsInf_UP, Downstream_nonOverlapGenes_strand_bases = gnsInf_DN)
    return(dat4)
}
#' Extracts gene information from bed files
#'
#' @param smap  character. Path to SMAP file.
#' @param bed  Text Bionano Bed file.
#' @param inputfmt character Whether the bed input is UCSC bed or Bionano bed.
#' Note: extract in bed format to be read by bedsv:
#' awk '{print $1,$3,$4,$5,$18,$7}' gencode.v19.annotation.gtf >HomoSapienGRCH19.bed
#' @param outpath  character Path for the output files.
#' @param n  numeric Number of genes to report which are nearest to the breakpoint.
#' Default is  	3.
#' @param returnMethod Character. Type of output Dataframe or in Text format.
#' @return Data Frame and Text file. Contains the smap with additional Gene Information
#' @examples
#' \dontrun{
#' }
#' @export
compSmapbed <- function(smap, bed, inputfmt = c("bed", "BNBed"), outpath, 
    n=3,returnMethod=c("Text","dataFrame")) {
	print("###Comparing SVs and Beds###")
    ## Checking if bed file is from UCSC or BN bed files.
    if (inputfmt == "BNBed") {
	    BNBed<-BNBed
        r1 <- readBNBedFiles(BNBed)
    } else {
        r1 <- buildrunBNBedFiles(bed,returnMethod="dataFrame")
    }
	##reading SMAPs and extracting data
    r2 <- readSMap(smap)
    chrom <- r2$RefcontigID1
    startpos <- r2$RefStartPos
    endpos <- r2$RefEndPos
    svid <- r2$SVIndex
    SVTyp <- r2$Type
	##Calls for the functions to extract overlap/non-overlap genes and calculate informations
	##for the same.
    dat3 <- overlapGenes(r1, chrom, startpos, endpos, svid)
	print(names(dat3))
    dat4 <- nonOverlapGenes(r1, chrom, startpos, endpos, svid)
	print(names(dat4))
	##Writing results in data frame and text files
    data1 <- data.frame(r2, OverlapGenes_strand_bases=dat3$OverlapGenes_strand_bases, dat4[, 2:ncol(dat4)])
	print(names(data1))
	if(returnMethod=="Text"){
    st1 <- strsplit(smap, split = "\\\\")
    st2 <- strsplit(st1[[1]][4], split = ".txt")
    fname <- paste(st2[[1]][1], "_Final_SVMAP.txt", sep = "")
    write.table(data1, file.path(outpath, fname))
	}
	else if (returnMethod=="dataFrame"){
    return(data1)
	}
	else{
	stop("Method of return incorrect")
	}
}

