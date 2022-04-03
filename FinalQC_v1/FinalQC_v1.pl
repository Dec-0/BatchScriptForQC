#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/.Modules";
use Parameter::BinList;
use QCRelated::QCStat;
use BedRelated::Bed;
use BamRelated::Align;

my ($HelpFlag,$BinList,$BeginTime);
my $ThisScriptName = basename $0;
my ($SPList,$QCLogFile,$Dir,$Samtools);
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script can be used to qc the alignment and merge the qc info previously.
  
  本脚本用于质控bam文件，两外可以用于混合对比前的质控结果，集中展示。

 -i      ( Required ) Sample list;
                      共5列，样本名、对应的Fastp-QC文件（多个时用‘,’隔开）、芯片、RawBam、FinalBam。
 -o      ( Required ) QC file for logging;

 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'i=s' => \$SPList,
	'o=s' => \$QCLogFile,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || !$SPList || !$QCLogFile)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	IfFileExist($SPList);
	$Dir = dirname $QCLogFile;
	IfDirExist($Dir);
	
	$BinList = BinListGet() if(!$BinList);
	$Samtools = BinSearch("Samtools",$BinList);
}

if(1)
{
	########## 需要统计的指标 ##########
	# 原始数据量
	# 原始reads数量
	# 平均reads读长
	# Q20
	# Q30
	# GC
	# N和low quality的数量
	# 接头污染read数
	# 芯片大小
	# 平均原始深度
	# 比对率（按reads数计算）
	# 重复率（按reads数计算）
	# 数据有效率（按reads数计算）
	# 平均有效深度
	# 插入片段峰值
	# Fold-80
	my (@RawReadsNum,@CleanReadsNum,@RawDataSize,@CleanDataSize,@TrimNumOfAdaptor,@ReadLen) = ();
	my (@RawNRate,@CleanNRate,@RawLowQualRate,@CleanLowQualRate,@RawErrorRate,@CleanErrorRate,@RawQ20,@CleanQ20,@RawQ30,@CleanQ30,@RawGCRate,@CleanGCRate,@TrimRateOfNLow) = ();
	my (@ChipSize,@AvgRawDepth,@AvgDepthOnChip,@AvgFinalDepthOnChip,@MapRate,@MapRateOnChip,@AvgDupRate,@DataEffectiveRate,@RawFold80,@FinalFold80,@RawPeakInsertSize,@FinalPeakInsertSize) = ();
	my $Return = `cat $SPList | cut -f 1 | sort | uniq`;
	my @SP = split /\n/, $Return;
	for my $i (0 .. $#SP)
	{
		# 逐个stat文件统计相关数据;
		$Return = `cat $SPList | grep ^'$SP[$i]'\$'\\t' | cut -f 2 | head -n1`;
		chomp $Return;
		my @StatFile = split /,/, $Return;
		my @StatInfo = ();
		($RawReadsNum[$i],$CleanReadsNum[$i],$RawDataSize[$i],$CleanDataSize[$i],$TrimNumOfAdaptor[$i]) = (0) x 5;
		for my $j (0 .. $#StatFile)
		{
			IfFileExist($StatFile[$j]);
			%{$StatInfo[$j]} = %{StatFileFormat($StatFile[$j])};
			
			$RawReadsNum[$i] += $StatInfo[$j]{"RawReadsNumber"};
			$CleanReadsNum[$i] += $StatInfo[$j]{"CleanReadsNumber"};
			$RawDataSize[$i] += $StatInfo[$j]{"RawDataSize"};
			$CleanDataSize[$i] += $StatInfo[$j]{"CleanDataSize"};
			$TrimNumOfAdaptor[$i] += $StatInfo[$j]{"DiscardNumDueToAdaptor"};
		}
		
		# 按比例合并数据;
		for my $j (0 .. $#StatFile)
		{
			$RawNRate[$i] += $StatInfo[$j]{"RawNRate"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanNRate[$i] += $StatInfo[$j]{"CleanNRate"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$RawLowQualRate[$i] += $StatInfo[$j]{"RawLowQualityRate"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanLowQualRate[$i] += $StatInfo[$j]{"CleanLowQualityRate"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$RawErrorRate[$i] += $StatInfo[$j]{"RawErrorRate"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanErrorRate[$i] += $StatInfo[$j]{"CleanErrorRate"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$RawQ20[$i] += $StatInfo[$j]{"RawQ20"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanQ20[$i] += $StatInfo[$j]{"CleanQ20"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$RawQ30[$i] += $StatInfo[$j]{"RawQ30"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanQ30[$i] += $StatInfo[$j]{"CleanQ30"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$RawGCRate[$i] += $StatInfo[$j]{"RawGCRate"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
			$CleanGCRate[$i] += $StatInfo[$j]{"CleanGCRate"} * $StatInfo[$j]{"CleanDataSize"} / $RawDataSize[$i];
			
			$TrimRateOfNLow[$i] += $StatInfo[$j]{"DiscardRateDueToNandLowQual"} * $StatInfo[$j]{"RawDataSize"} / $RawDataSize[$i];
		}
		
		# Reads' length (默认是PE);
		$ReadLen[$i] = int(($RawDataSize[$i] / $RawReadsNum[$i]) / 2);
		
		# 比对相关;
		###### 芯片大小;
		my $Chip = `cat $SPList | grep ^'$SP[$i]'\$'\\t' | cut -f 3 | head -n1`;
		chomp $Chip;
		$ChipSize[$i] = BedSize($Chip);
		printf "[ %s ] ChipSize for %s:\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$ChipSize[$i];
		###### 原始深度;
		$AvgRawDepth[$i] = $RawDataSize[$i] / $ChipSize[$i];
		###### 去重前平均深度;
		my $SortedBam = `cat $SPList | grep ^'$SP[$i]'\$'\\t' | cut -f 4 | head -n1`;
		chomp $SortedBam;
		my ($tAvgDepth,$tFold80,$tRef) = BasicDepthInfoOnChip($SortedBam,$Chip,$Samtools);
		$AvgDepthOnChip[$i] = $tAvgDepth;
		$RawFold80[$i] = $tFold80;
		printf "[ %s ] Average Depth And Fold-80 After Mapping for %s:\t%s\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$AvgDepthOnChip[$i],$RawFold80[$i];
		###### 去重后平均深度;
		my $FinalBam = `cat $SPList | grep ^'$SP[$i]'\$'\\t' | cut -f 5 | head -n1`;
		chomp $FinalBam;
		($tAvgDepth,$tFold80,$tRef) = BasicDepthInfoOnChip($FinalBam,$Chip,$Samtools);
		$AvgFinalDepthOnChip[$i] = $tAvgDepth;
		$FinalFold80[$i] = $tFold80;
		printf "[ %s ] Average Depth And Fold-80 After Dup-Marking for %s:\t%s\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$AvgFinalDepthOnChip[$i],$FinalFold80[$i];
		###### 整体及区域内的reads数量及比对率（区域内reads总数 / 质控后reads总数）
		my $RawReadsNumOnRef = ReadsNumCountOnRef($SortedBam,$Samtools);
		$MapRate[$i] = $RawReadsNumOnRef / ($CleanReadsNum[$i] * 2);
		printf "[ %s ] Mapping rate for %s:\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$MapRate[$i];
		my $RawReadsNumOnChip = ReadsNumCountOnChip($SortedBam,$Chip,$Samtools);
		$MapRateOnChip[$i] = $RawReadsNumOnChip / ($CleanReadsNum[$i] * 2);
		printf "[ %s ] Mapping rate on target for %s:\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$MapRateOnChip[$i];
		###### 区域内的有效reads数量及数据有效率（区域内reads总数 / 质控后reads总数）
		my $FinalReadsNum = ReadsNumCountOnChip($FinalBam,$Chip,$Samtools);
		$DataEffectiveRate[$i] = $FinalReadsNum / ($CleanReadsNum[$i] * 2);
		###### 重复率（去重后的read1数量 / 去重前的read1数量）
		my $RawReadsPairNum = ReadsPairNumCount($SortedBam,$Samtools);
		my $FinalReadsPairNum = ReadsPairNumCount($FinalBam,$Samtools);
		$AvgDupRate[$i] = 1 - $FinalReadsPairNum / $RawReadsPairNum;
		printf "[ %s ] Duplication rate for %s:\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$AvgDupRate[$i];
		###### PeakInsertSize;
		$RawPeakInsertSize[$i] = PeakInsertSize($SortedBam,$Samtools);
		$FinalPeakInsertSize[$i] = PeakInsertSize($FinalBam,$Samtools);
		printf "[ %s ] Peak Insert Size Before And After Dup-Marking for %s:\t%s\t%s.\n",TimeString(time,$BeginTime),$SP[$i],$RawPeakInsertSize[$i],$FinalPeakInsertSize[$i];
		
		
		# 格式转换;
		$RawReadsNum[$i] = NumAddComma($RawReadsNum[$i]);
		$CleanReadsNum[$i] = NumAddComma($CleanReadsNum[$i]);
		$RawDataSize[$i] = NumAddComma($RawDataSize[$i]);
		$CleanDataSize[$i] = NumAddComma($CleanDataSize[$i]);
		$RawNRate[$i] = Dot2Percent($RawNRate[$i],3);
		$CleanNRate[$i] = Dot2Percent($CleanNRate[$i],3);
		$RawLowQualRate[$i] = Dot2Percent($RawLowQualRate[$i],3);
		$CleanLowQualRate[$i] = Dot2Percent($CleanLowQualRate[$i],3);
		$RawErrorRate[$i] = Dot2Percent($RawErrorRate[$i],3);
		$CleanErrorRate[$i] = Dot2Percent($CleanErrorRate[$i],3);
		$RawQ20[$i] = Dot2Percent($RawQ20[$i],3);
		$CleanQ20[$i] = Dot2Percent($CleanQ20[$i],3);
		$RawQ30[$i] = Dot2Percent($RawQ30[$i],3);
		$CleanQ30[$i] = Dot2Percent($CleanQ30[$i],3);
		$RawGCRate[$i] = Dot2Percent($RawGCRate[$i],3);
		$CleanGCRate[$i] = Dot2Percent($CleanGCRate[$i],3);
		$TrimRateOfNLow[$i] = Dot2Percent($TrimRateOfNLow[$i],3);
		$TrimNumOfAdaptor[$i] = NumAddComma($TrimNumOfAdaptor[$i]);
		
		$ChipSize[$i] = NumAddComma($ChipSize[$i]);
		$AvgRawDepth[$i] = DotFormat($AvgRawDepth[$i],1);
		$AvgDepthOnChip[$i] = DotFormat($AvgDepthOnChip[$i],1);
		$RawFold80[$i] = DotFormat($RawFold80[$i],2);
		$AvgFinalDepthOnChip[$i] = DotFormat($AvgFinalDepthOnChip[$i],1);
		$FinalFold80[$i] = DotFormat($FinalFold80[$i],2);
		$MapRate[$i] = Dot2Percent($MapRate[$i],3);
		$MapRateOnChip[$i] = Dot2Percent($MapRateOnChip[$i],3);
		$DataEffectiveRate[$i] = Dot2Percent($DataEffectiveRate[$i],3);
		$AvgDupRate[$i] = Dot2Percent($AvgDupRate[$i],3);
	}
	
	if(1)
	{
		open(LOG,"> $QCLogFile") or die $!;
		print LOG join("\t","#Items",@SP),"\n";
		print LOG join("\t","AverageReadLength",@ReadLen),"\n";
		print LOG join("\t","Raw_ReadsPairNumber",@RawReadsNum),"\n";
		print LOG join("\t","Clean_ReadsPairNumber",@CleanReadsNum),"\n";
		print LOG join("\t","Raw_DataSize",@RawDataSize),"\n";
		print LOG join("\t","Clean_DataSize",@CleanDataSize),"\n";
		print LOG join("\t","Raw_RateOfN",@RawNRate),"\n";
		print LOG join("\t","Clean_RateOfN",@CleanNRate),"\n";
		print LOG join("\t","Raw_RateOfLowQual",@RawLowQualRate),"\n";
		print LOG join("\t","Clean_RateOfLowQual",@CleanLowQualRate),"\n";
		print LOG join("\t","Raw_AverageErrorRate",@RawErrorRate),"\n";
		print LOG join("\t","Clean_AverageErrorRate",@CleanErrorRate),"\n";
		print LOG join("\t","Raw_Q20",@RawQ20),"\n";
		print LOG join("\t","Clean_Q20",@CleanQ20),"\n";
		print LOG join("\t","Raw_Q30",@RawQ30),"\n";
		print LOG join("\t","Clean_Q30",@CleanQ30),"\n";
		print LOG join("\t","Raw_RateOfGC",@RawGCRate),"\n";
		print LOG join("\t","Clean_RateOfGC",@CleanGCRate),"\n";
		print LOG join("\t","DiscardedRateOfNAndLowQuality",@TrimRateOfNLow),"\n";
		print LOG join("\t","DiscardedNumberOfAdaptor",@TrimNumOfAdaptor),"\n";
		# 芯片及比对信息;
		print LOG join("\t","ChipSize",@ChipSize),"\n";
		print LOG join("\t","AverageTheoreticalDepth",@AvgRawDepth),"\n";
		print LOG join("\t","AverageRawDepth",@AvgDepthOnChip),"\n";
		print LOG join("\t","AverageFinalDepth",@AvgFinalDepthOnChip),"\n";
		print LOG join("\t","MappingRate",@MapRate),"\n";
		print LOG join("\t","MappingRateOnTarget",@MapRateOnChip),"\n";
		print LOG join("\t","DuplicationRate",@AvgDupRate),"\n";
		print LOG join("\t","DataEffectiveRatio",@DataEffectiveRate),"\n";
		print LOG join("\t","Raw_Fold80",@RawFold80),"\n";
		print LOG join("\t","Final_Fold80",@FinalFold80),"\n";
		print LOG join("\t","Raw_PeakInsertSize",@RawPeakInsertSize),"\n";
		print LOG join("\t","Final_PeakInsertSize",@FinalPeakInsertSize),"\n";
		close LOG;
	}
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########
