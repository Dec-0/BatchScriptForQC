#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/.Modules";
use Parameter::BinList;
use BamRelated::Align;

my ($HelpFlag,$BinList,$BeginTime);
my $ThisScriptName = basename $0;
my ($Bam,$Dir,$Prefix,$Samtools);
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script can be used to visulize the distribution of insert size.
  
  本脚本主要用于常规质控。

 -i      ( Required ) Bam file;
 -o      ( Required ) Directory for logging;

 -prefix ( Optional ) Prefix of the logging file (default: the prefix of input bam file);
 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'i=s' => \$Bam,
	'o=s' => \$Dir,
	'prefix:s' => \$Prefix,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || !$Bam || !$Dir)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	IfFileExist($Bam);
	$Dir = IfDirExist($Dir);
	unless($Prefix)
	{
		my $BaseName = basename $Bam;
		$BaseName =~ s/\.bam$//;
		$Prefix = $BaseName;
	}
	
	$BinList = BinListGet() if(!$BinList);
	$Samtools = BinSearch("Samtools",$BinList);
}

if(1)
{
	my ($PeakSize,$tRef) = PeakInsertSize($Bam,$Samtools);
	my @SizeInfo = @{$tRef};
	
	open(SINFO,"> $Dir/$Prefix\.InsertSize.Distr") or die $!;
	for my $i (0 .. $#SizeInfo)
	{
		next unless($SizeInfo[$i]);
		print SINFO join("\t",$i,$SizeInfo[$i]),"\n";
	}
	close SINFO;
	`echo '$PeakSize' > $Dir/$Prefix\.InsertSize.Peak`;
	
	my ($MaxX,$MaxY) = (1000,0);
	$MaxY = $SizeInfo[$PeakSize];
	
	&do_plot($Prefix,$MaxX,$MaxY,$PeakSize);
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########
sub do_plot
{
	my ($prefix,$xlim,$ylim,$peak_insz) = @_;
	my $leftlim = 0.5*$peak_insz;
	my $rightlim = 2*$peak_insz;
	my $Rline = <<Rline;
	a<-read.table("$Dir/$prefix.InsertSize.Distr")
	x<-a[,1]
	y<-a[,2]
	if(x[1]==0)
	{
		all_sum = sum(y)
		no_0_sum = sum(y[2:length(y)])
		plot_y = round(c(y[1]/all_sum*100, y[2:length(y)]/no_0_sum*100) , 2)
		ylim = max(plot_y[2:length(y)])
		
		temp = cumsum(plot_y[2:length(y)])
		index_25 = which(temp>=25)[1]
		index_75 = which(temp>=75)[1]
		index_x = index_25:index_75
		index_y = plot_y[(index_25+1):(index_75+1)] - 0.1
	}else{
		all_sum = sum(y)
		plot_y = round( y/all_sum*100, 2)
		ylim = max(plot_y)
		
		temp = cumsum(plot_y)
		index_25 = which(temp>=25)[1]
		index_75 = which(temp>=75)[1]
		index_x = index_25:index_75
		index_y = plot_y[index_25:index_75] - 0.1
	}

	#png("$Dir/$prefix.InsertSize.png",type="cairo",width=900,height=600)
	pdf("$Dir/$prefix.InsertSize.pdf",width=12,height=8)
	m <- matrix(c(1,1,2,1),2,2)
	layout(m, widths=c(2,2),heights=c(2,2))

	plot(x,plot_y,xlim=c(1,$xlim),ylim=c(0,1.2*ylim),col=rgb( 0,0.85,0.5),type="l",lwd=1.5,xlab="Insert Size(bp)",ylab="Frequency(%)",main="Distribution of InsertSize")
	for(n in 1:length(index_x))
	{
		lines(c(index_x[n], index_x[n]), c(0, index_y[n]), col=rgb( 0,0.85,0.5))
	}
	labels_y = min(c(index_y[1]/2, index_y[length(index_y)]/2))
	points($peak_insz,ylim,col="MediumPurple1",type="p",pch=16,cex=1.2)
	points(index_25,index_y[1],col="DeepSkyBlue2",type="p",pch=16,cex=1.2)
	points(index_75,index_y[length(index_x)],col="Orange2",type="p",pch=16,cex=1.2)
	temp = c( paste(sep=" ", 'peak', '=', $peak_insz) , paste(sep=" ", 'Threshold:25%', '=', index_25),paste(sep=" ", 'Threshold:75%', '=', index_75))
	legend("topleft", temp , text.col=c('MediumPurple1','DeepSkyBlue2','Orange2'), ncol=1, bty='n', cex=1.1)
	plot(x,plot_y,xlim=c($leftlim,$rightlim), ylim=c(0,1.2*ylim),type="l",xlab="",ylab="",col=rgb( 0,0.85,0.5))
	lines(c($peak_insz,$peak_insz),c(0,ylim),col="MediumPurple1",lty=2)
	points($peak_insz,ylim,col="MediumPurple1",type="p",pch=16)
	lines(c(index_25,index_25),c(0,plot_y[index_25]),col="DeepSkyBlue2",lty=2)
	points(index_25,plot_y[index_25],col="DeepSkyBlue2",type="p",pch=16)
	lines(c(index_75,index_75),c(0,plot_y[index_75]),col="Orange2",lty=2)
	points(index_75,plot_y[index_75],col="Orange2",type="p",pch=16)
	out = rbind(c("Library Peak Size(bp):", $peak_insz), c("Library 25%~75% Size(bp):", paste(sep="", '[ ', index_25,' , ', index_75, ' ]' )) )
	write.table(out, "$Dir/$prefix.InsertSize.txt", sep="\t", eol="\n", quote=F, row.names=F, col.names=F)
	dev.off()
Rline
	open RS, ">", "$Dir/$prefix.InsertSize.R";
	print RS $Rline;
	close RS;
	system("Rscript $Dir/$prefix.InsertSize.R");
}