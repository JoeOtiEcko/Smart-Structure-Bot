//+------------------------------------------------------------------+
//|                                          Smart Structure Pro.mq5 |
//|                                   Copyright 2026, Joseph Otieno. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Joe Otieno 2026."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


//========================== INPUTS =================================

input int   ScanBars         = 300;
input int   PivotStrength    = 2;
input int PivotLength        = 3;

input color SwingHighColor   = clrRed;
input color SwingLowColor    = clrLime;

input bool  ShowHighs        = true;
input bool  ShowLows         = true;

input int MinSwingRetracePoints = 300;
input int MaxStoredSwings = 500;
input int MinStructureDistance = 800;
input double MajorStrengthMultiplier = 1.50;

//===================================================================

struct SwingPoint
  {
   datetime          time;
   double            price;
   int               index;
   bool              isHigh;
   bool              confirmed;
   bool              broken;

  };

SwingPoint Swings[500];
int SwingCount = 0;


//===================================================================

struct PivotPoint
  {
   int               index;
   double            price;
   bool              isHigh;

   double            strength;

   bool              major;
  };

PivotPoint Pivots[1000];
int PivotCount = 0;

double AverageStrength = 0.0;

//==================================================================

enum ENUM_STRUCTURE
  {
   ST_NONE = 0,
   ST_HH,
   ST_HL,
   ST_LH,
   ST_LL
  };

//==============================================================

enum ENUM_TREND
  {
   TREND_UNKNOWN = 0,
   TREND_BULLISH,
   TREND_BEARISH
  };

ENUM_TREND CurrentTrend = TREND_UNKNOWN;

//===============================================================

struct StructureSwing
  {
   int               index;
   double            price;
   bool              isHigh;
   ENUM_STRUCTURE    structure;
  };

StructureSwing StructureSwings[500];
int StructureCount = 0;


//======================= MARKET DATA ===============================

MqlRates PriceData[];

datetime LastBar = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Smart Structure Pro Started");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }

//+------------------------------------------------------------------+
//| Expert Tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime CurrentBar = iTime(_Symbol,_Period,0);

   if(CurrentBar == LastBar)
      return;

   LastBar = CurrentBar;

   ScanMarket();
  }

//+------------------------------------------------------------------+
//| Read market data                                                 |
//+------------------------------------------------------------------+
void ScanMarket()
  {
   ArraySetAsSeries(PriceData,true);

   int copied = CopyRates(
                   _Symbol,
                   _Period,
                   0,
                   ScanBars,
                   PriceData
                );

   if(copied <= 0)
     {
      Comment("Unable to read market.");
      return;
     }


   CollectPivots();

   FilterPivots();

   BuildStructureSwings();

   ClassifyStructure();

   ClearSwingObjects();

   for(int i=0; i<StructureCount; i++)
     {
      DrawStructureSwing(i);
     }

  }

// DrawStructureLines();


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FilterPivots()
  {
   if(PivotCount < 2)
      return;

   int write = 0;

   for(int i=0; i<PivotCount; i++)
     {
      if(write == 0)
        {
         Pivots[write++] = Pivots[i];
         continue;
        }

      if(Pivots[write-1].isHigh == Pivots[i].isHigh)
        {
         if(Pivots[i].isHigh)
           {
            // Keep the higher HIGH
            if(Pivots[i].price > Pivots[write-1].price)
               Pivots[write-1] = Pivots[i];
           }
         else
           {
            // Keep the lower LOW
            if(Pivots[i].price < Pivots[write-1].price)
               Pivots[write-1] = Pivots[i];
           }
        }
      else
        {
         Pivots[write++] = Pivots[i];
        }
     }

   PivotCount = write;

   Print("----------------------");
   Print("FilterPivots()");
   Print("PivotCount = ", PivotCount);

   for(int i=0; i<PivotCount; i++)
     {
      Print(
         i,
         " ",
         (Pivots[i].isHigh ? "HIGH" : "LOW"),
         " index=",
         Pivots[i].index,
         " price=",
         DoubleToString(Pivots[i].price,_Digits)
      );
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuildStructureSwings()
  {
   StructureCount = 0;

   for(int i=0; i<PivotCount; i++)
     {
      StructureSwings[StructureCount].index = Pivots[i].index;
      StructureSwings[StructureCount].price = Pivots[i].price;
      StructureSwings[StructureCount].isHigh = Pivots[i].isHigh;
      // Structure assigned later in ClassifyStructure()

      Print(
         "Swing ",
         StructureCount,
         " ",
         (StructureSwings[StructureCount].isHigh ? "HIGH" : "LOW"),
         " Index=",
         StructureSwings[StructureCount].index,
         " Price=",
         DoubleToString(StructureSwings[StructureCount].price,_Digits)
      );

      StructureCount++;
     }

   Print("StructureCount = ", StructureCount);
  }


//+------------------------------------------------------------------+
//| Classify Structure Swings                                        |
//+------------------------------------------------------------------+
void ClassifyStructure()
  {
   double previousHigh = 0;
   double previousLow = 0;

   bool firstHigh = true;
   bool firstLow = true;

   for(int i = 0; i < StructureCount; i++)
     {
      if(StructureSwings[i].isHigh)
        {
         if(firstHigh)
           {
            StructureSwings[i].structure = ST_NONE;
            previousHigh = StructureSwings[i].price;
            firstHigh = false;
           }
         else
           {
            if(StructureSwings[i].price > previousHigh)
               StructureSwings[i].structure = ST_HH;
            else
               StructureSwings[i].structure = ST_LH;

            previousHigh = StructureSwings[i].price;
           }
        }
      else
        {
         if(firstLow)
           {
            StructureSwings[i].structure = ST_NONE;
            previousLow = StructureSwings[i].price;
            firstLow = false;
           }
         else
           {
            if(StructureSwings[i].price > previousLow)
               StructureSwings[i].structure = ST_HL;
            else
               StructureSwings[i].structure = ST_LL;

            previousLow = StructureSwings[i].price;
           }
        }

      Print("Swing ", i,
            "  Price=", DoubleToString(StructureSwings[i].price, _Digits),
            "  Type=", EnumToString(StructureSwings[i].structure));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculatePivotStrength()
  {
   for(int i = 0; i < PivotCount; i++)
     {
      double move = 0.0;

      if(Pivots[i].isHigh)
        {
         double lowest = Pivots[i].price;

         for(int j = Pivots[i].index; j >= MathMax(Pivots[i].index - 20, 0); j--)
           {
            if(PriceData[j].low < lowest)
               lowest = PriceData[j].low;
           }

         move = Pivots[i].price - lowest;
        }
      else
        {
         double highest = Pivots[i].price;

         for(int j = Pivots[i].index; j >= MathMax(Pivots[i].index - 20, 0); j--)
           {
            if(PriceData[j].high > highest)
               highest = PriceData[j].high;
           }

         move = highest - Pivots[i].price;
        }

      Pivots[i].strength = move;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectMajorPivots()
  {
   if(PivotCount < 3)
      return;

// First and last pivots are always major
   Pivots[0].major = true;
   Pivots[PivotCount-1].major = true;

   for(int i=1; i<PivotCount-1; i++)
     {
      if(Pivots[i].strength > Pivots[i-1].strength &&
         Pivots[i].strength >= Pivots[i+1].strength)
        {
         Pivots[i].major = true;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateAverageStrength()
  {
   AverageStrength = 0.0;

   if(PivotCount == 0)
      return;

   for(int i=0; i<PivotCount; i++)
      AverageStrength += Pivots[i].strength;

   AverageStrength /= PivotCount;
  }

//===================================================================

double LastHH = 0.0;
double LastLL = 0.0;

datetime LastBullBoS = 0;
datetime LastBearBoS = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DetectBoS()
  {
   LastHH = 0.0;
   LastLL = 0.0;

// Find latest HH and LL
   for(int i = StructureCount - 1; i >= 0; i--)
     {
      if(LastHH == 0.0 &&
         StructureSwings[i].structure == ST_HH)
        {
         LastHH = StructureSwings[i].price;
        }

      if(LastLL == 0.0 &&
         StructureSwings[i].structure == ST_LL)
        {
         LastLL = StructureSwings[i].price;
        }

      if(LastHH > 0 && LastLL > 0)
         break;
     }

   double close = PriceData[1].close;

   if(LastHH > 0 &&
      close > LastHH &&
      PriceData[1].time != LastBullBoS)
     {
      LastBullBoS = PriceData[1].time;

      Print("Bullish Break of Structure");
     }

   if(LastLL > 0 &&
      close < LastLL &&
      PriceData[1].time != LastBearBoS)
     {
      LastBearBoS = PriceData[1].time;

      Print("Bearish Break of Structure");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawFilteredPivots()
  {
   for(int i = 0; i < PivotCount; i++)
     {
      if(Pivots[i].isHigh)
         DrawSwingHigh(Pivots[i].index);
      else
         DrawSwingLow(Pivots[i].index);
     }
  }
//+------------------------------------------------------------------+
//| Candidate Swing High                                             |
//+------------------------------------------------------------------+
bool IsCandidateHigh(int i)
  {
   if(i < PivotStrength)
      return(false);

   if(i > ArraySize(PriceData)-PivotStrength-1)
      return(false);

   for(int j=1;j<=PivotStrength;j++)
     {
      if(PriceData[i].high <= PriceData[i-j].high)
         return(false);

      if(PriceData[i].high <= PriceData[i+j].high)
         return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Candidate Swing Low                                              |
//+------------------------------------------------------------------+
bool IsCandidateLow(int i)
  {
   if(i < PivotStrength)
      return(false);

   if(i > ArraySize(PriceData)-PivotStrength-1)
      return(false);

   for(int j=1;j<=PivotStrength;j++)
     {
      if(PriceData[i].low >= PriceData[i-j].low)
         return(false);

      if(PriceData[i].low >= PriceData[i+j].low)
         return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Draw Swing High                                                  |
//+------------------------------------------------------------------+
void DrawSwingHigh(int index)
  {
   if(!ShowHighs)
      return;

   string name = "SwingHigh_" + IntegerToString(index);

   if(ObjectFind(0,name)>=0)
      return;

   ObjectCreate(
      0,
      name,
      OBJ_ARROW,
      0,
      PriceData[index].time,
      PriceData[index].high
   );

   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,233);
   ObjectSetInteger(0,name,OBJPROP_COLOR,SwingHighColor);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);

  }

//+------------------------------------------------------------------+
//| Draw Swing Low                                                   |
//+------------------------------------------------------------------+
void DrawSwingLow(int index)
  {
   if(!ShowLows)
      return;

   string name = "SwingLow_" + IntegerToString(index);

   if(ObjectFind(0,name)>=0)
      return;

   ObjectCreate(
      0,
      name,
      OBJ_ARROW,
      0,
      PriceData[index].time,
      PriceData[index].low
   );

   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,234);
   ObjectSetInteger(0,name,OBJPROP_COLOR,SwingLowColor);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);

  }

//+------------------------------------------------------------------+
//| Draw Structure Swing                                             |
//+------------------------------------------------------------------+
void DrawStructureSwing(int swing)
  {
   int index = StructureSwings[swing].index;

   string arrowName = "Swing_" + IntegerToString(swing);

   if(ObjectFind(0, arrowName) < 0)
     {
      ObjectCreate(
         0,
         arrowName,
         OBJ_ARROW,
         0,
         PriceData[index].time,
         StructureSwings[swing].price
      );

      if(StructureSwings[swing].isHigh)
         ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE,233);
      else
         ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE,234);

      ObjectSetInteger(
         0,
         arrowName,
         OBJPROP_COLOR,
         StructureSwings[swing].isHigh ? SwingHighColor : SwingLowColor
      );

      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH,2);
     }

   string text="";

   switch(StructureSwings[swing].structure)
     {
      case ST_HH:
         text="HH";
         break;
      case ST_HL:
         text="HL";
         break;
      case ST_LH:
         text="LH";
         break;
      case ST_LL:
         text="LL";
         break;
      default:
         return;
     }

   string labelName="Label_"+IntegerToString(swing);

   if(ObjectFind(0,labelName)>=0)
      return;

   double offset=20*_Point;

   if(StructureSwings[swing].isHigh)
      offset=-offset;

   ObjectCreate(
      0,
      labelName,
      OBJ_TEXT,
      0,
      PriceData[index].time,
      StructureSwings[swing].price+offset
   );

   ObjectSetString(0,labelName,OBJPROP_TEXT,text);
   ObjectSetInteger(0,labelName,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,labelName,OBJPROP_FONTSIZE,9);
  }

//+------------------------------------------------------------------+
//| Detect Candidate Swings                                          |
//+------------------------------------------------------------------+
void DetectCandidateSwings()
  {
   int HighCount = 0;
   int LowCount  = 0;

   for(int i=ArraySize(PriceData)-PivotStrength-1; i>=PivotStrength; i--)
     {
      if(IsCandidateHigh(i))
        {
         if(ConfirmHigh(i))
           {
            HighCount++;
            DrawSwingHigh(i);
            StoreSwing(i,true);
           }
        }

      if(IsCandidateLow(i))
        {
         if(ConfirmLow(i))
           {
            LowCount++;
            DrawSwingLow(i);
            StoreSwing(i,false);
           }
        }
     }

   Comment(
      "Smart Structure Pro v0.1.3\n\n",
      "Bars Loaded : ",ArraySize(PriceData),
      "\nCandidate Highs : ",HighCount,
      "\nCandidate Lows  : ",LowCount,
      "\nConfirmed Swings : ",SwingCount
   );
  }

//====================================================================

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void StoreSwing(int index,bool high)
  {
   if(SwingCount>=MaxStoredSwings)
      return;

   Swings[SwingCount].time      = PriceData[index].time;
   Swings[SwingCount].price     = high ? PriceData[index].high : PriceData[index].low;
   Swings[SwingCount].index     = index;
   Swings[SwingCount].isHigh    = high;
   Swings[SwingCount].confirmed = true;
   Swings[SwingCount].broken    = false;

   SwingCount++;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ConfirmHigh(int index)
  {
   double highest = PriceData[index].high;

   for(int i = index-1; i >= index-10 && i >= 0; i--)
     {
      if(PriceData[i].high > highest)
         return(false);

      double retrace = highest - PriceData[i].low;

      if(retrace >= MinSwingRetracePoints * _Point)
         return(true);
     }

   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ConfirmLow(int index)
  {
   double lowest = PriceData[index].low;

   for(int i = index-1; i >= index-10 && i >= 0; i--)
     {
      if(PriceData[i].low < lowest)
         return(false);

      double retrace = PriceData[i].high - lowest;

      if(retrace >= MinSwingRetracePoints * _Point)
         return(true);
     }

   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CollectPivots()
  {
   PivotCount = 0;

   int bars = ArraySize(PriceData);

   for(int i = bars-PivotLength-1; i >= PivotLength; i--)
     {
      bool isHigh = true;
      bool isLow  = true;

      for(int j=1; j<=PivotLength; j++)
        {
         if(PriceData[i].high <= PriceData[i-j].high)
            isHigh=false;

         if(PriceData[i].high <= PriceData[i+j].high)
            isHigh=false;

         if(PriceData[i].low >= PriceData[i-j].low)
            isLow=false;

         if(PriceData[i].low >= PriceData[i+j].low)
            isLow=false;
        }

      if(isHigh)
        {
         Pivots[PivotCount].index=i;
         Pivots[PivotCount].price=PriceData[i].high;
         Pivots[PivotCount].isHigh=true;
         Pivots[PivotCount].strength=0;
         Pivots[PivotCount].major=false;


         PivotCount++;
        }

      if(isLow)
        {
         Pivots[PivotCount].index=i;
         Pivots[PivotCount].price=PriceData[i].low;
         Pivots[PivotCount].isHigh=false;
         Pivots[PivotCount].strength=0;
         Pivots[PivotCount].major=false;

         PivotCount++;
        }
     }

   Print("========================");
   Print("FINAL PivotCount = ",PivotCount);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearSwingObjects()
  {
   int total = ObjectsTotal(0);

   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);

      if(StringFind(name,"SwingHigh_")==0 ||
         StringFind(name,"SwingLow_")==0 ||
         StringFind(name,"StructureLabel_")==0 ||
         StringFind(name,"StructureLine_")==0)
        {
         ObjectDelete(0,name);
        }
     }
  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
