# Package Name
package QCRelated::QCStat;

# Exported name
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(StatFileFormat NumAddComma Dot2Percent DotFormat);

use FindBin qw($Bin);
use File::Basename;

sub StatFileFormat
{
	my $StatFile = $_[0];
	
	my %StatInfo = ();
	my $Return = ();
	# Reads信息，包括原始的和trim后的;
	$Return = `cat $StatFile | grep ^'Number of Reads:'\$'\\t' | cut -f 2`;
	chomp $Return;
	$StatInfo{"RawReadsNumber"} = $Return;
	$Return = `cat $StatFile | grep ^'Number of Reads:'\$'\\t' | cut -f 3`;
	chomp $Return;
	$StatInfo{"CleanReadsNumber"} = $Return;
	
	# DataSize;
	$Return = `cat $StatFile | grep ^'Data Size:'\$'\\t' | cut -f 2`;
	chomp $Return;
	$StatInfo{"RawDataSize"} = $Return;
	$Return = `cat $StatFile | grep ^'Data Size:'\$'\\t' | cut -f 3 | cut -d '(' -f 1`;
	chomp $Return;
	$StatInfo{"CleanDataSize"} = $Return;
	$Return = `cat $StatFile | grep ^'Data Size:'\$'\\t' | cut -f 3 | cut -d '(' -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanDataRate"} = $Return / 100;
	
	# N比例;
	$Return = `cat $StatFile | grep ^'N of fq1:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawNRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'N of fq1:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanNRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'N of fq2:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawNRateOfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'N of fq2:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanNRateOfFq2"} = $Return / 100;
	$StatInfo{"RawNRate"} = ($StatInfo{"RawNRateOfFq1"} + $StatInfo{"RawNRateOfFq2"}) / 2;
	$StatInfo{"CleanNRate"} = ($StatInfo{"CleanNRateOfFq1"} + $StatInfo{"CleanNRateOfFq2"}) / 2;
	
	# Low Quality比例;
	$Return = `cat $StatFile | grep ^'Low qual base of fq1(<=5):'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawLowQualityRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Low qual base of fq1(<=5):'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanLowQualityRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Low qual base of fq2(<=5):'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawLowQualityRateOfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Low qual base of fq2(<=5):'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanLowQualityRateOfFq2"} = $Return / 100;
	$StatInfo{"RawLowQualityRate"} = ($StatInfo{"RawLowQualityRateOfFq1"} + $StatInfo{"RawLowQualityRateOfFq2"}) / 2;
	$StatInfo{"CleanLowQualityRate"} = ($StatInfo{"CleanLowQualityRateOfFq1"} + $StatInfo{"CleanLowQualityRateOfFq2"}) / 2;
	
	# Q20;
	$Return = `cat $StatFile | grep ^'Q20 of fq1:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawQ20OfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q20 of fq1:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanQ20OfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q20 of fq2:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawQ20OfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q20 of fq2:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanQ20OfFq2"} = $Return / 100;
	$StatInfo{"RawQ20"} = ($StatInfo{"RawQ20OfFq1"} + $StatInfo{"RawQ20OfFq2"}) / 2;
	$StatInfo{"CleanQ20"} = ($StatInfo{"CleanQ20OfFq1"} + $StatInfo{"CleanQ20OfFq2"}) / 2;
	
	# Q30;
	$Return = `cat $StatFile | grep ^'Q30 of fq1:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawQ30OfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q30 of fq1:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanQ30OfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q30 of fq2:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawQ30OfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Q30 of fq2:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanQ30OfFq2"} = $Return / 100;
	$StatInfo{"RawQ30"} = ($StatInfo{"RawQ30OfFq1"} + $StatInfo{"RawQ30OfFq2"}) / 2;
	$StatInfo{"CleanQ30"} = ($StatInfo{"CleanQ30OfFq1"} + $StatInfo{"CleanQ30OfFq2"}) / 2;
	
	# GC Rate;
	$Return = `cat $StatFile | grep ^'GC of fq1:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawGCRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'GC of fq1:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanGCRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'GC of fq2:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawGCRateOfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'GC of fq2:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanGCRateOfFq2"} = $Return / 100;
	$StatInfo{"RawGCRate"} = ($StatInfo{"RawGCRateOfFq1"} + $StatInfo{"RawGCRateOfFq2"}) / 2;
	$StatInfo{"CleanGCRate"} = ($StatInfo{"CleanGCRateOfFq1"} + $StatInfo{"CleanGCRateOfFq2"}) / 2;
	
	# Error Rate;
	$Return = `cat $StatFile | grep ^'Error of fq1:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawErrorRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Error of fq1:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanErrorRateOfFq1"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Error of fq2:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"RawErrorRateOfFq2"} = $Return / 100;
	$Return = `cat $StatFile | grep ^'Error of fq2:'\$'\\t' | cut -f 3 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"CleanErrorRateOfFq2"} = $Return / 100;
	$StatInfo{"RawErrorRate"} = ($StatInfo{"RawErrorRateOfFq1"} + $StatInfo{"RawErrorRateOfFq2"}) / 2;
	$StatInfo{"CleanErrorRate"} = ($StatInfo{"CleanErrorRateOfFq1"} + $StatInfo{"CleanErrorRateOfFq2"}) / 2;
	
	# Discarded Reads due to N and low quality;
	$Return = `cat $StatFile | grep ^'Discard Reads related to N and low qual:'\$'\\t' | cut -f 2 | cut -d '%' -f 1`;
	chomp $Return;
	$StatInfo{"DiscardRateDueToNandLowQual"} = $Return / 100;
	
	# Discarded Reads due to Adaptor;
	$Return = `cat $StatFile | grep ^'Discard Reads related to Adapter:'\$'\\t' | cut -f 2`;
	chomp $Return;
	$StatInfo{"DiscardNumDueToAdaptor"} = $Return;
	
	
	return \%StatInfo;
}

sub NumAddComma
{
	my $Number = $_[0];
	
	$Number =~ s/(?<=\d)(?=(\d{3})+$)/,/g;
	
	return $Number;
}

sub Dot2Percent
{
	my $Num = $_[0];
	my $DecimalNum = $_[1];
	$DecimalNum = 0 unless($DecimalNum);
	
	$Num = $Num * 100;
	if($DecimalNum)
	{
		$DecimalNum .= "f";
		$Num = sprintf("%.$DecimalNum",$Num);
	}
	$Num .= "%";
	
	return $Num;
}

sub DotFormat
{
	my $Num = $_[0];
	my $DecimalNum = $_[1];
	$DecimalNum = 0 unless($DecimalNum);
	
	if($DecimalNum)
	{
		# 格式化;
		$DecimalNum .= "f";
		$Num = sprintf("%.$DecimalNum",$Num);
	}
	else
	{
		# 四舍五入;
		$Num = int($Num + 0.5);
	}
	
	return $Num;
}

1;