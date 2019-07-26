unit main;

{$mode objfpc}{$H+}
{$INLINE ON}


interface

uses
  Classes, SysUtils, FileUtil,  Forms,
  Controls, Graphics, Dialogs, Menus, StdCtrls,  ExtCtrls, ufcoder,
  typinfo, DateUtils;

 type
  Card_Data = Array of Byte;
  key_Data = Array [0..5] of Byte ;
  { TMainForm }

  TMainForm = class(TForm)
    btnOpen  : TButton;
    BtnInfo  : TButton;
    btnRead  : TButton;
    cbRaw    : TCheckBox;
    cbTxt    : TCheckBox;
    checkAdvanced: TCheckBox;
    txtReaderType: TEdit;
    txtPortName: TEdit;
    txtPortInterface: TEdit;
    txtArg: TEdit;
    GroupBox1: TGroupBox;
    groupAdvanced: TGroupBox;
    Label1   : TLabel;
    lblReaderType: TLabel;
    lblPortName: TLabel;
    lblPortInterface: TLabel;
    lblArg: TLabel;
    Memo1    : TMemo;
    mInfo    : TMemo;
    mLog     : TMemo;

    procedure btnOpenClick(Sender: TObject);
    procedure BtnInfoClick(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure checkAdvancedClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);

  private

    procedure  Open;
    procedure  GetInfo;
    function   DevInfo  : AnsiString;
    procedure  LinearRaw;
    function   WriteBin (C_FNAME: String; var buffer: Array of Byte): Integer;
    function   HexArrayToString (var bin: Array of Byte): String;

 private
     GlobalUID      :String;

  public
    { public declarations }
  end;




var
  MainForm        :      TMainForm;
  Reader_Conn     :      Boolean = False;
  GlobalCardType  :      Byte;
  StrUID          :      AnsiString;
  MaxBl           :      Integer;
  BLen            :      Integer;
  FN_Bin,FN_Txt   :      String;
  Cont_Str        :      TStringList;
  ReaderTypeStr: String ='';
  ReaderSerialStr : String = '';
  ReaderSerialArray : Array [0..7] of char;

implementation


{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
 Cont_Str:= TStringList.Create;
end;

procedure TMainForm.btnOpenClick(Sender: TObject);

begin
  open();  //procedure to open reader
  if Reader_Conn then
     begin


     btnInfo.Enabled:= True;
     btnInfo.SetFocus;
     end;
end;

procedure TMainForm.BtnInfoClick(Sender: TObject);
begin
  btnRead.Enabled:= False;
  Memo1.Clear;
  mInfo.Clear;
  GetInfo;  // procedure to get Card Info
  BtnRead.Enabled:= True;
end;

procedure TMainForm.btnReadClick(Sender: TObject);
var
   c: Byte = $00;
   r: DL_Status;
begin
 r:= GetDLogicCardType(c); //check if card is still present
 if c=GlobalCardType      //check if previously detected card type match to existing card type
    then
       begin
       if r = 0
          then
              begin
              LinearRaw;
              Memo1.Lines.Clear;
              Memo1.Lines.Add
                          (
                          'Info generated on '+FormatDateTime('HH:mm:ss DD-MM-YYYY',Now)
                          );
              Memo1.Lines.Add(mInfo.Text);
              Memo1.Lines.Add(Trim(Cont_Str.Text));
              if cbTxt.Checked
                 then
                     begin
                     Memo1.Lines.SaveToFile(FN_Txt);
                     mLog.Lines.Append(
                                       FormatDateTime('HH:mm:ss',Now)+
                                       ' - Txt file saved to '+FN_Txt
                                       );
                     end;
              end
          else
              Memo1.Lines.Text:= UFR_Status2String(r);    // error occured
       end

    else Memo1.Lines.Text:= 'Wrong Card type';

 btnRead.Enabled:= False;
 btnInfo.SetFocus;
end;

procedure TMainForm.checkAdvancedClick(Sender: TObject);
begin
    if checkAdvanced.Checked = True
       then begin
           groupAdvanced.Enabled := True;
       end
    else begin
           groupAdvanced.Enabled := False;
       end;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
 btnOpen.SetFocus;
end;

procedure TMainForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
 ReaderClose();  //close reader
 if Assigned (Cont_Str) then Cont_Str.Free;  //release stringlist to prevent memory leaks
end;


Procedure TMainForm.GetInfo;
var
    RT_Result,
    Card_Result,
    UID_Result,
    ReaderType    :  LongInt;
    UidSize       :  Byte = 0;
    CardType      :  Byte = 0;
    bBr           :  Byte = 0;
    baCardUID     :  Array[0..9] of Byte;
    blockname     :  String = '';
begin

    MaxBl:= 0;
    BLen:= 0;
    GlobalCardType:= 0;
    GlobalUID:= '';
    if Reader_Conn then
    begin
       RT_Result:= GetReaderType(@ReaderType);  //get type of reader
       if RT_Result=DL_OK
        then
          begin
          mLog.Lines.Append(
                            FormatDateTime('HH:mm:ss',Now)+
                            ' - ReaderType - $'+IntToHex(readerType,8)+
                            ' - '+UFR_Status2String(RT_Result)
                            );
          Card_Result:= GetDlogicCardType(CardType);   //get card type
          if Card_Result=DL_OK then
             begin
             GlobalCardType:= CardType;
             case GlobalCardType of
                 $01..$0A : blockname:= 'page';
                 $20..$24 : blockname:= 'block';
                 $25..$ff : blockname:= '';
                 end;
             mLog.Lines.Append(
                               FormatDateTime('HH:mm:ss',Now)+
                               ' - DL_CardType - $'+
                               IntToHex(CardType,2)+' : '+CardType2String(Cardtype)+
                               ' - '+UFR_Status2String(Card_Result)
                               );
             mInfo.Lines.Add(
                             'Card Type: 0x'+IntToHex(CardType,2)+
                             ' - '+CardType2String(Cardtype)
                             );
             MaxBl:= maxBlocks(CardType);
             BLen:= BytesPerBlock(CardType);
             UID_Result:= GetCardIdEx(@CardType,@baCardUID[0],@UidSize);   //get card UID
             if UID_Result=DL_OK
                then
                    begin
                    for bBr:= 0 to UidSize-1 do GlobalUID:= GlobalUID+IntToHex(baCardUID[bBr],2);
                    mLog.Lines.Append(
                                      FormatDateTime('HH:mm:ss',Now)+
                                      ' - UID : $'+GlobalUID+' - '+
                                      UFR_Status2String(UID_Result)
                                      );
                    end
                else
                    begin
                    mLog.Lines.Append(
                                      FormatDateTime('HH:mm:ss',Now)+
                                      ' - UID : ERROR'+' - '+
                                      UFR_Status2String(UID_Result)
                                      );

                    end;

             mInfo.Lines.Add(
                             'Card UID 0x'+GlobalUID+
                             '   ---  UID Length '+IntToStr(UidSize)+' Bytes'
                             );
             mInfo.Lines.Add(
                             IntToStr (MaxBl) +' '+blockname+'s, '+
                             IntToStr(BLen)+' Bytes per '+blockname+
                             ', total '+IntToStr(MaxBl*BLen)+' Bytes'
                             );


             end
          else
             begin
             mLog.Lines.Append(
                               FormatDateTime('HH:mm:ss',Now)+
                               ' - CardType - ERROR'+
                               UFR_Status2String(Card_Result)
                               );

             mInfo.Clear;
             mInfo.Lines.Add('NO Card');
             end;
          end
        else
          begin
          mLog.Lines.Append(
                            FormatDateTime('HH:mm:ss',Now)+
                            ' - ReaderType - ERROR '+' - '+
                            UFR_Status2String(RT_Result)
                            );
          end;
      end;
end;



procedure TMainForm.Open;
var
    ConnResult :LongInt;
    reader_type,
    port_name,
    port_interface,
    arg :string;

    reader_type_int,
    port_interface_int :Longint;


begin
    if not Reader_Conn
       then
           begin
           if  checkAdvanced.Checked
              then
              begin
                  reader_type := txtReaderType.Text;
                  port_name := txtPortName.Text;
                  port_interface := txtPortInterface.Text;
                  arg := txtArg.Text;

                 try
                     reader_type_int := StrToInt(reader_type);
                 except
                     On E : EConvertError do
                     begin
                         ShowMessage('Incorrect parameter: Reader type');
                         txtReaderType.SetFocus();
                     end;
                 end;

                 try
                   if port_interface='U'
                     then
                         begin
                             port_interface_int := 85;
                         end
                  else if port_interface='T'
                      then
                         begin
                             port_interface_int := 84;
                         end
                  else
                      begin
                          port_interface_int := StrToInt(port_interface);
                      end;

                  except
                      On E : EConvertError do begin
                          ShowMessage('Incorrect parameter: Port interface');
                          txtPortInterface.SetFocus();
                      end;
                  end;
                  ConnResult:= ReaderOpenEx(reader_type_int, PChar(port_name), port_interface_int , PChar(arg));
               end
           else
               begin
                   ConnResult:= ReaderOpen();
               end;

           if ConnResult=DL_OK
              then
                  begin
                  Reader_Conn:= True;
                  mLog.Lines.append(DevInfo);
                  ReaderUISignal(1,1);
                  end
              else
                  begin
                  Reader_Conn:= False;
                  mLog.Lines.Append(
                                    FormatDateTime('HH:mm:ss',Now)+' '+
                                    UFR_Status2String(ConnResult)+
                                    ' - Reader NOT Connected'
                                    );
                  end;
           end;
end;



function TMainForm.DevInfo: AnsiString;

   var
   R_Type,
   DLL_String: Pchar;
   HW_Major,
   HW_Minor,
   FW_Major,
   FW_Minor,
   FW_build  :  Byte;
begin
  GetReaderHardwareVersion(@HW_Major, @HW_Minor);
  GetReaderFirmwareVersion(@FW_Major, @FW_Minor);
  GetBuildNumber(@FW_build);
  GetReaderType(@R_Type);
  GetReaderSerialDescription(@ReaderSerialArray);
  ReaderSerialStr:=AnsiString(ReaderSerialArray);
  DLL_String :=GetDllVersionStr();
  Result:=  ' '+
            Format('Reader SN: %s',[ReaderSerialStr])+' | '+
            Format('HW: %D.%D',[HW_Major, HW_Minor])+' | '+
            Format('FW: %D.%D.%D',[FW_Major, FW_Minor, FW_Build])+' | '+
            Format('DLL: %s',[DLL_String]);

end;



Procedure TMainForm.LinearRaw;
var
   i,
   j,
   k,
   DataLength,
   Bytes,
   Pages      : Integer;

   Returned   : Word;
   StartProc,
   StopProc   : TTime;
   Diff_ms    : Int64;
   Data,
   DataOut,
   tmpBlock,
   Unknown    : Array of Byte;
   BadBlock   : AnsiString ='';
   KeyPK      : Array [0..5] of Byte = ($ff,$ff,$ff,$ff,$ff,$ff);
   CmdResult  : DL_STATUS;

begin
  Returned    := 0;
  StartProc   := Now;
  StopProc    := Now;
  diff_ms     := 0;
  Cont_Str.Clear;
  DataLength  := MaxTotalBytes(GlobalCardType);
  SetLength(Data,DataLength);
  SetLength(DataOut,DataLength);
  for i:= 0 to Length(Data)-1
      do
      begin
      Data[i]:= $00;
      DataOut[i]:= $00;
      end;
  Bytes:= BytesPerBlock(GlobalCardType);
  Pages:= MaxBlocks(GlobalCardType);
  SetLength(tmpBlock,Bytes);
  SetLength(Unknown,Bytes);
  for k:= 1 to Bytes do BadBlock:= BadBlock+' --';
  for k:= 0 to Length(Unknown)-1 do Unknown[k]:= $EE;
  FN_Bin:= GlobalUID+'_'+FormatDateTime('YYYY-MM-DD_HH-mm-ss',Now)+'.mfd';
  FN_Txt:= GlobalUID+'_'+FormatDateTime('YYYY-MM-DD_HH-mm-ss',Now)+'_nfo.txt';

      try
        CmdResult:= LinRowRead_PK(@Data[0],0,DataLength,Returned,MIFARE_AUTHENT1A,@KeyPK);
        //if CmdResult=$0E
        //   then
        //       CmdResult:= LinRowRead_PK(@Data[0],0,DataLength,Returned,MIFARE_AUTHENT1B,@KeyPK);
        if (CmdResult=0) or (Returned>0)
           then
               begin
               StopProc:= Now;
               diff_ms:= MilliSecondsBetween(StopProc,StartProc);

                  case Bytes
                    of
                    4:  Cont_Str.Add('Dec Hex   Bytes         ASCII ');
                    16: Cont_Str.Add('Dec Hex   Bytes                                                ASCII ');
                  end;

               for i:=  0 to Pages-1
                   do
                   begin
                   for j:= 0 to Bytes-1
                       do
                         tmpBlock[j]:= Data[i*Bytes+j];

                   if (
                      (GlobalCardType=$21)   //if Mifare 1K, define trailer blocks
                      and
                      (i in [ 3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,63])
                      )
                      then
                       for k:=  0 to 5 do tmpBlock[k]:= KeyPK[k]; //change guessed Key A in block data

                   if (
                      (GlobalCardType=$22)  //if Mifare 4K, define trailer blocks
                      and
                      (i in
                      [
                      3,7,11,15,19,23,27,31,
                      35,39,43,47,51,55,59,63,
                      67,71,75,79,83,87,91,95,99,
                      103,107,111,115,119,123,127,
                      143,159,175,191,207,223,239,255])
                      )
                      then
                       for k:=  0 to 5 do tmpBlock[k]:= KeyPK[k];  //change guessed Key A in block data

                   if (i*Bytes)<=Returned then
                    begin
                   for j:=  0 to Bytes-1 do DataOut[i*Bytes+j]:= tmpBlock[j];
                   Cont_Str.Add
                   (Format('%.03d',[i])+
                    ' '+IntToHex(i,2)+
                    ' - '+HexArrayToString(tmpBlock)+
                    '  ['+BinToAscii(tmpBlock)+
                    ']');

                     end
                   else       //if error during reading, not enough bytes returned
                   begin
                      for j:=  0 to Bytes-1 do DataOut[i*Bytes+j]:= Unknown[j];
                   Cont_Str.Add
                    (
                    Format('%.03d',[i])+
                    ' '+IntToHex(i,2)+
                    ' - '+BadBlock+
                    '  [Uknown Data]'           //add unknown data to dump
                    );
                    end;
                   Application.ProcessMessages;


                   end;

               end                      //error occured
               else  Cont_Str.Add
                                 (IntToStr(Returned)+
                                   ' Error :'+
                                   UFR_Status2String(CmdResult)
                                   );

        finally
        if cbRaw.Checked
           then
               begin
               if WriteBin(FN_Bin,DataOut)=0         //write raw dump to file
                  then
                      mLog.Lines.Append(
                       FormatDateTime('HH:mm:ss',Now)+
                       ' - Raw dump saved to '+FN_Bin
                       )
                  else mLog.Lines.Append(
                       FormatDateTime('HH:mm:ss',Now)+
                       ' - Error occured while saving '+FN_Bin+' file'
                       )

         end;
        SetLength(Data,0);          //clear dynamic arrays
        SetLength(DataOut,0);
        SetLength(tmpBlock,0);
        SetLength(Unknown,0);
        BadBlock:= '';
     end;


     mLog.Lines.Append(
                       FormatDateTime('HH:mm:ss',Now)+' - '+
                       UFR_Status2String(CmdResult)+
                       ' Returned: '+IntToStr(Returned)+' Bytes'
                       );
     if diff_ms>0 then
                       mLog.Lines.Append
                       (
                       FormatDateTime('HH:mm:ss',Now)+
                       ' - Reading time : '+IntToStr(diff_ms)+' msec'
                       );

     if Returned=DataLength then Cont_Str.Add(#13#10+'Card read, Reading time : '+IntToStr(diff_ms)+' msec')
                            else Cont_Str.Add(#13#10+'Card partialy read, Bytes Returned:'+IntToStr(Returned)+' of '+IntToStr(DataLength)+', Reading time : '+IntToStr(diff_ms)+' msec')
end;

//util - convert byte array to string hex representation

Function TMainForm.HexArrayToString(var bin : Array of Byte): String;
var i,c: Integer;
    tmpres:String='';
begin
Result:= '';
c:= Length(bin);
  for i :=  0 to c-1 do
           begin
           tmpres:= IntToHex(bin[i],2);
           Result:= Result+' '+tmpres;
           end;
end;


///------------------- write raw bin dump to file ----///
function  TMainForm.WriteBin(C_FNAME:String;var  buffer: Array of Byte):Integer;
var
  fsOut    : TFileStream;
begin
 Result:= -1;
  // Catch errors in case the file cannot be created
  try
    // Create the file stream instance, write to it and free it to prevent Memory leaks
    fsOut :=  TFileStream.Create( C_FNAME, fmCreate);
    fsOut.Write(Buffer, SizeOf(Buffer));
    fsOut.Free;
  // Handle errors
  except
    on E:Exception do
       begin
       ShowMessage('File '+ C_FNAME+' could not be created because: '+ E.Message);
       Result:= -1;
       end;
  end;


  Result:= 0;

 end;


end.

