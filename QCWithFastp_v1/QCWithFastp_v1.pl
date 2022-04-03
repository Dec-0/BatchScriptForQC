#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/.Modules";
use Parameter::BinList;

my ($HelpFlag,$BinList,$BeginTime);
my $ThisScriptName = basename $0;
my ($Input,$Json,$Html,$ThreadNum,$FastpBin);
my @CleanFq;
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script was used to qc with fastp.

 -i      ( Required ) Fq files seperated by ',';
                      可以是fastq文件路径，以‘,’分隔
                      注意：没有‘,’时，识别成记录fastq路径的文件。
 -json   ( Required ) Json file;
 -html   ( Required ) Html file;

 -t      ( Optional ) Thread number (default: 1);
 -o      ( Optional ) Clean fq (multi times);
 -bin    ( Optional ) List for searching of related bin or scripts;
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'i=s' => \$Input,
	'json=s' => \$Json,
	'html=s' => \$Html,
	't:i' => \$ThreadNum,
	'o:s' => \@CleanFq,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || !$Input || !$Json || !$Html)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	
	
	$BinList = BinListGet() unless($BinList);
	$FastpBin = BinSearch("Fastp",$BinList);
	$ThreadNum = 1 unless($ThreadNum);
}

if(1)
{
	my @OriFq;
	if($Input =~ /,/)
	{
		@OriFq = split /,/, $Input;
	}
	else
	{
		IfFileExist($Input);
		my $tmp = `cat $Input`;
		chomp $tmp;
		@OriFq = split /\t/, $tmp;
	}
	for my $i (0 .. $#OriFq)
	{
		IfFileExist($OriFq[$i]);
	}
	die "[ Error ] Clean fq not 2.\n" unless($#CleanFq == 1 || !@CleanFq);;
	
	if(@CleanFq)
	{
		my $ReadLen = &MaxReadLenConfirm($OriFq[0]);
		print "[ Command line ] $FastpBin -i $OriFq[0] -o $CleanFq[0] -I $OriFq[1] -O $CleanFq[1] --json=$Json --html=$Html -Q --length_required $ReadLen\n";
		`$FastpBin -i $OriFq[0] -o $CleanFq[0] -I $OriFq[1] -O $CleanFq[1] --json=$Json --html=$Html -Q --length_required $ReadLen --thread $ThreadNum`;
	}
	else
	{
		print "[ Command line ] $FastpBin -i $OriFq[0] -I $OriFq[1] --json=$Json --html=$Html -Q\n";
		`$FastpBin -i $OriFq[0] -I $OriFq[1] --json=$Json --html=$Html -Q`;
	}
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########
# 取前250行reads中最长的reads长度;
sub MaxReadLenConfirm
{
	my $Fq = $_[0];
	my $Len = 0;
	
	if($Fq =~ /\.fq\.gz$/)
	{
		$Len = `zcat $Fq | head -n 1000 | awk '{if(NR % 4 == 2){print \$0}}' | awk 'BEGIN{Len=0;tLen=0}{tLen=length(\$0);if(tLen > Len){Len=tLen}}END{print Len}'`;
	}
	else
	{
		$Len = `cat $Fq | head -n 1000 | awk '{if(NR % 4 == 2){print \$0}}' | awk 'BEGIN{Len=0;tLen=0}{tLen=length(\$0);if(tLen > Len){Len=tLen}}END{print Len}'`;
	}
	chomp $Len;
	
	return $Len;
}