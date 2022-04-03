#include <stdio.h>
#include <stdlib.h>  // for file handle;
#include <getopt.h> // for argument;
#include <time.h>
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

time_t start,end,dur_min,dur_sec,dur_hour;
unsigned char BuffContent[2000000];
unsigned int LineStart,LineEnd,BuffSize,ReadLen,ReadNum;
unsigned int MaxBuffSize = 1000000;
unsigned int BaseA[1000],BaseT[1000],BaseC[1000],BaseG[1000],BaseN[1000];
unsigned long QualDistr[1000],TotalQual[1000];


// _________________________________________________
//
//                  Sub functions
// _________________________________________________
int TimeLog(unsigned char *String)
{
	time(&end);
	dur_sec = end - start;
	if(dur_sec < 60)
	{
		printf("[ %ds ] %s.\n",dur_sec,String);
	}
	else
	{
		dur_min = (int)(dur_sec / 60);
		dur_sec = (int)(dur_sec % 60);
		if(dur_min < 60)
		{
			printf("[ %dmin%ds ] %s.\n",dur_min,dur_sec,String);
		}
		else
		{
			dur_hour = (int)(dur_min / 60);
			dur_min = (int)(dur_min % 60);
			printf("[ %dh%dmin ] %s.\n",dur_hour,dur_min,String);
		}
	}
	
	return 1;
}

int LineCap()
{
	static unsigned int TempEnd;
	unsigned int i;
	
	if(LineEnd < BuffSize - 1)
	{
		LineEnd ++;
		LineStart = LineEnd;
	}
	// 'LineEnd == BuffSize' was set for the 1st rounding;
	else if(LineEnd == BuffSize || LineEnd == BuffSize - 1)
	{
		BuffSize = fread(BuffContent,1,MaxBuffSize,stdin);
		if(BuffSize <= 0)
		{
			return 0;
		}
		LineStart = 0;
		LineEnd = 0;
	}
	else
	{
		LineStart = TempEnd + 1;
		LineEnd = LineStart;
	}
	
	for(LineEnd;LineEnd < BuffSize;LineEnd ++)
	{
		if(BuffContent[LineEnd] == '\n')
		{
			return 1;
		}
	}
	
	// relocating;
	TempEnd = MaxBuffSize;
	for(i = LineStart;i < LineEnd;i ++)
	{
		TempEnd ++;
		BuffContent[TempEnd] = BuffContent[i];
	}
	LineStart = MaxBuffSize + 1;
	LineEnd = TempEnd;
	BuffSize = fread(BuffContent,1,MaxBuffSize,stdin);
	if(BuffSize == 0)
	{
		BuffSize = LineEnd;
		return 1;
	}
	
	for(TempEnd = 0;TempEnd < BuffSize;TempEnd ++)
	{
		LineEnd ++;
		BuffContent[LineEnd] = BuffContent[TempEnd];
		if(BuffContent[TempEnd] == '\n')
		{
			return 1;
		}
	}
	
	return 0;
}

int Num2Char(unsigned int Num, unsigned char *Char)
{
	unsigned int i,BitNum,tmpId;
	
	BitNum = 10;
	for(i = 1;i < 20;i ++)
	{
		if(Num < BitNum)
		{
			break;
		}
		BitNum = BitNum * 10;
	}
	BitNum = BitNum / 10;
	
	tmpId = 0;
	while(BitNum)
	{
		Char[tmpId] = (unsigned int)(Num / BitNum) % 10 + 48;
		BitNum = (unsigned int)(BitNum / 10);
		tmpId ++;
	}
	Char[tmpId] = '\0';
	
	return 1;
}

int ReadInfoCollect()
{
	unsigned int LineId,tId,i,flag;
	unsigned long tQual;
	
	memset(BaseA,0,1000*sizeof(unsigned int));
	memset(BaseT,0,1000*sizeof(unsigned int));
	memset(BaseC,0,1000*sizeof(unsigned int));
	memset(BaseG,0,1000*sizeof(unsigned int));
	memset(BaseN,0,1000*sizeof(unsigned int));
	memset(TotalQual,0,1000*sizeof(unsigned long));
	memset(QualDistr,0,100*sizeof(unsigned long));
	
	
	LineEnd = 0;
	BuffSize = 1;
	LineId = 0;
	ReadNum = 0;
	ReadLen = 0;
	flag = 0;
	while(LineCap())
	{
		LineId ++;
		
		if(LineId == 2)
		{
			if(flag == 0)
			{
				ReadLen = LineEnd - LineStart;
				flag = 1;
			}
			for(i = LineStart;i < LineEnd;i ++)
			{
				tId = i - LineStart;
				if(BuffContent[i] == 'A')
				{
					BaseA[tId] ++;
				}
				else if(BuffContent[i] == 'T')
				{
					BaseT[tId] ++;
				}
				else if(BuffContent[i] == 'C')
				{
					BaseC[tId] ++;
				}
				else if(BuffContent[i] == 'G')
				{
					BaseG[tId] ++;
				}
				else
				{
					BaseN[tId] ++;
				}
			}
		}
		else if(LineId == 4)
		{
			if(LineEnd - LineStart > ReadLen && flag == 1)
			{
				printf("[ Error ] %d -> %d (ReadLen: %d).\n",LineStart,LineEnd,ReadLen);
				flag = 2;
			}
			
			for(i = LineStart;i < LineEnd;i ++)
			{
				tQual = BuffContent[i] - 33;
				
				tId = i - LineStart;
				TotalQual[tId] += tQual;
				QualDistr[tQual] ++;
			}
			
			LineId = 0;
			ReadNum ++;
		}
	}
	
	return 1;
}

// ___________________________________
//
//            Main Part
// ___________________________________
int main(int argc, char *argv[])
{
	unsigned int i;
	time(&start);
	
	
	// Collect the reads info from sam;
	ReadInfoCollect();
	
	// time and rate logging;
	printf("[ Reads' Number ]\t%d\n",ReadNum);
	printf("[ Reads' Length ]\t%d\n",ReadLen);
	for(i = 0;i < ReadLen;i ++)
	{
		printf("[ Base A T C G N and TotalQual for Pos]\t%d\t%d\t%d\t%d\t%d\t%d\t%ld\n",i,BaseA[i],BaseT[i],BaseC[i],BaseG[i],BaseN[i],TotalQual[i]);
	}
	for(i = 0;i <= 100;i ++)
	{
		printf("[ Total Number for Quality]\t%d\t%ld\n",i,QualDistr[i]);
	}
}