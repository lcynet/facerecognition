unit FaceRecognition;

{$mode Delphi}

interface

uses
  Windows, ActiveX, Dialogs, SysUtils;

type
  _face_encodings = packed array[0..128-1] of Single;
  pface_encodings = ^_face_encodings;

  _ar_face_encodings = array of _face_encodings;

  _face_locations = packed record
    face_location_top: Integer;
    face_location_left: Integer;
    face_location_bottom: Integer;
    face_location_right: Integer;
  end;
  pface_locations = ^_face_locations;

  ar_face_locations = array of _face_locations;

  IFaceRecognitionDLL = interface
  ['{80B18DAD-3EDE-4239-914D-B0F260E224B0}']
    function LoadImageFile(FileName: WideString): Integer; stdcall;
    function LoadImageStream(bmp_stream: IStream): Integer; stdcall;
    function FaceLocations(var face_locations:pface_locations; var face_locations_length: Integer ): Integer; stdcall;
    function FaceEncodings(var _face_encodings:pface_encodings; var face_encodings_Length: Integer ): Integer; stdcall;
    function ReleaseLocationsArray(var face_locations:pface_locations): Integer; stdcall;
    function ReleaseEncodingsArray(var pfe: pface_encodings): Integer; stdcall;
    function CompareFace(SourceFace: _face_encodings; DestinationFace: _face_encodings; var Distance: Single): Integer; stdcall;
  end;

  IFaceRecognition = interface
  ['{9C3CB1C7-720C-4B65-9D77-C88A7189A154}']
    function LoadImageFile( FileName: WideString ): Integer;
    function LoadImageStream( bmp_stream: IStream ): Integer;
    function FaceLocations( var face_locations: ar_face_locations ): Integer;
    function FaceEncodings( var face_encodings: _ar_face_encodings ): Integer;
    function CompareFace( SourceFace: _face_encodings; DestinationFace: _face_encodings; var Distance: Single ): Integer;
  end;

  TFaceRecognition = class(TInterfacedObject,IFaceRecognition)
  private
    fFRDLL: IFaceRecognitionDLL;
  public
    Constructor Create;
  public
    function LoadImageFile( FileName: WideString ): Integer;
    function LoadImageStream( bmp_stream: IStream ): Integer;
    function FaceLocations( var face_locations: ar_face_locations ): Integer;
    function FaceEncodings( var face_encodings: _ar_face_encodings ): Integer;
    function CompareFace( SourceFace: _face_encodings; DestinationFace: _face_encodings; var Distance: Single ): Integer;
  end;

const
    {$IF DEFINED(WIN64)}
    DLibWrapperDLLPath = 'dlibwrapper64bit.dll';
    {$ELSEIF DEFINED(WINDOWS)}
    DLibWrapperDLLPath = 'dlibwrapper32bit.dll';
    {$ENDIF}



var
  DLibWrapperDLL: THandle;

  compare_face: function ( SourceFace: _face_encodings; DestinationFace: _face_encodings; var Distance: Single ):Integer; stdcall;
  function face_recognition( const filename: WideString; face_locations: ar_face_locations ):Integer; overload;
  function face_recognition( const filename: WideString; face_locations: ar_face_locations; face_encodings: _ar_face_encodings ): Integer; overload;
  function face_recognition_stream( bmp_stream: IStream; var face_locations: ar_face_locations; var face_encodings: _ar_face_encodings ): Integer;

  function CreateFaceRecognition: IFaceRecognitionDLL; safecall; //experimental

implementation
var
  _face_recognition: function ( const FileName:WideString; var face_locations:pface_locations; var face_locations_length: Integer; face_encodings:pface_encodings=nil; face_encodings_Length: PInteger=nil ):Integer; stdcall;
  _face_recognition_stream: function ( bmp_stream: IStream; var face_locations:pface_locations; var face_locations_length: Integer; face_encodings:pface_encodings=nil; face_encodings_Length: PInteger=nil ):Integer; stdcall;
  release_face_locations: function ( var face_locations:pface_locations ):Integer; stdcall;
  release_face_encodings: function ( var face_encodings:pface_encodings ):Integer; stdcall;

function CreateFaceRecognition; external DLibWrapperDLLPath name 'CreateFaceRecognition'; //experimental

function face_recognition( const FileName: WideString; face_locations: ar_face_locations ):Integer;
var
  pface_locations_origin: pface_locations;
  pface_locations_temp: pface_locations;
  face_locations_length: Integer;
  i: Integer;
begin
  _face_recognition( filename, pface_locations_origin, face_locations_length, nil, nil );
  pface_locations_temp := pface_locations_origin;
  SetLength(face_locations, face_locations_length);
  for i := 0 to face_locations_length - 1 do
  begin
    face_locations[i].face_location_top    := pface_locations_temp^.face_location_top;
    face_locations[i].face_location_left   := pface_locations_temp^.face_location_left;
    face_locations[i].face_location_bottom := pface_locations_temp^.face_location_bottom;
    face_locations[i].face_location_right  := pface_locations_temp^.face_location_right;
    inc( pface_locations_temp );
  end;
  release_face_locations( pface_locations_origin );
end;

function face_recognition( const filename: WideString; face_locations: ar_face_locations; face_encodings: _ar_face_encodings):Integer;
var
  pface_locations_origin: pface_locations;
  pface_locations_temp: pface_locations;
  face_locations_length: Integer;
  pface_encodings_origin: pface_encodings;
  pface_encodings_temp: pface_encodings;
  face_encodings_length: Integer;
  i: Integer;
  j: Integer;
begin
  _face_recognition( filename, pface_locations_origin, face_locations_length, @pface_encodings_origin, @face_encodings_length );
  pface_locations_temp := pface_locations_origin;
  SetLength(face_locations, face_locations_length);
  for i := 0 to face_locations_length - 1 do
  begin
    face_locations[i].face_location_top    := pface_locations_temp^.face_location_top;
    face_locations[i].face_location_left   := pface_locations_temp^.face_location_left;
    face_locations[i].face_location_bottom := pface_locations_temp^.face_location_bottom;
    face_locations[i].face_location_right  := pface_locations_temp^.face_location_right;
    inc( pface_locations_temp );
  end;
  release_face_locations( pface_locations_origin );

  pface_encodings_temp := pface_encodings_origin;
  SetLength(face_encodings, face_encodings_length);
  for i := 0 to face_encodings_length - 1 do
  begin
    for j := 0 to 128 - 1 do
    begin
      face_encodings[i][j] := pface_encodings_temp^[j];
    end;
    inc( pface_encodings_temp );
  end;
  release_face_encodings( pface_encodings_origin );
end;

function face_recognition_stream( bmp_stream: IStream; var face_locations: ar_face_locations; var face_encodings: _ar_face_encodings):Integer;
var
  pface_locations_origin: pface_locations;
  pface_locations_temp: pface_locations;
  face_locations_length: Integer;
  pface_encodings_origin: pface_encodings;
  pface_encodings_temp: pface_encodings;
  face_encodings_length: Integer;
  i: Integer;
  j: Integer;
begin
  _face_recognition_stream( bmp_stream, pface_locations_origin, face_locations_length, @pface_encodings_origin, @face_encodings_length );
  pface_locations_temp := pface_locations_origin;
  SetLength(face_locations, face_locations_length);
  for i := 0 to face_locations_length - 1 do
  begin
    face_locations[i].face_location_top    := pface_locations_temp^.face_location_top;
    face_locations[i].face_location_left   := pface_locations_temp^.face_location_left;
    face_locations[i].face_location_bottom := pface_locations_temp^.face_location_bottom;
    face_locations[i].face_location_right  := pface_locations_temp^.face_location_right;
    inc( pface_locations_temp );
  end;
  release_face_locations( pface_locations_origin );

  pface_encodings_temp := pface_encodings_origin;
  SetLength(face_encodings, face_encodings_length);
  for i := 0 to face_encodings_length - 1 do
  begin
    for j := 0 to 128 - 1 do
    begin
      face_encodings[i][j] := pface_encodings_temp^[j];
    end;
    inc( pface_encodings_temp );
  end;
  release_face_encodings( pface_encodings_origin );
end;


{ TFaceRecognition }

function TFaceRecognition.CompareFace( SourceFace, DestinationFace: _face_encodings; var Distance: Single ): Integer;
begin
  result := fFRDLL.CompareFace( SourceFace, DestinationFace, Distance );
end;

constructor TFaceRecognition.Create;
begin
  fFRDLL := CreateFaceRecognition;
end;

function TFaceRecognition.FaceEncodings( var face_encodings: _ar_face_encodings ): Integer;
var
  pface_encodings_temp: pface_encodings;
  pface_encodings_origin: pface_encodings;
  face_encodings_length: Integer;
  i: Integer;
  j: Integer;
begin
  SetLength( face_encodings, 0 );
  fFRDLL.FaceEncodings(pface_encodings_origin, face_encodings_length);
  pface_encodings_temp := pface_encodings_origin;
  SetLength( face_encodings, face_encodings_length );
  for i := 0 to face_encodings_length - 1 do
  begin
    for j := 0 to 128 - 1 do
    begin
      face_encodings[i][j] := pface_encodings_temp^[j];
    end;
    inc( pface_encodings_temp );
  end;
  fFRDLL.ReleaseEncodingsArray( pface_encodings_origin ); //free DLL memory
end;

function TFaceRecognition.FaceLocations( var face_locations: ar_face_locations ): Integer;
var
  pface_locations_temp: pface_locations;
  pface_locations_origin: pface_locations;
  face_locations_length: Integer;
  i: Integer;
begin
  SetLength( face_locations, 0 );
  fFRDLL.FaceLocations( pface_locations_origin, face_locations_length );
  pface_locations_temp := pface_locations_origin;
  SetLength( face_locations, face_locations_length );
  for i := 0 to face_locations_length - 1 do
  begin
    face_locations[i].face_location_top    := pface_locations_temp^.face_location_top;
    face_locations[i].face_location_left   := pface_locations_temp^.face_location_left;
    face_locations[i].face_location_bottom := pface_locations_temp^.face_location_bottom;
    face_locations[i].face_location_right  := pface_locations_temp^.face_location_right;
    inc( pface_locations_temp );
  end;
  fFRDLL.ReleaseLocationsArray(pface_locations_origin); //free DLL memory
end;

function TFaceRecognition.LoadImageFile( FileName: WideString ): Integer;
begin
  result := fFRDLL.LoadImageFile( FileName );
end;

function TFaceRecognition.LoadImageStream( bmp_stream: IStream ): Integer;
begin
  result := fFRDLL.LoadImageStream( bmp_stream );
end;

initialization
  if not FileExists( 'dlib_face_recognition_resnet_model_v1.dat' ) then
  begin
    ShowMessage( 'dlib_face_recognition_resnet_model_v1.dat not found! Please download and then decompress from "http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2"' );
    Halt;
  end;

  if not FileExists( 'shape_predictor_5_face_landmarks.dat' ) then
  begin
    ShowMessage( 'dlib_face_recognition_resnet_model_v1.dat not found! Please download and then decompress from "http://dlib.net/files/shape_predictor_5_face_landmarks.dat.bz2"' );
    Halt;
  end;

  DLibWrapperDLL := LoadLibrary( PChar( DLibWrapperDLLPath ) );
  if DLibWrapperDLL = 0 then begin
    ShowMessage( 'Error: Cannot load ' + DLibWrapperDLLPath );
    Halt;
  end;
  @_face_recognition := GetProcAddress(DLibWrapperDLL, PChar('face_recognition'));
  if @_face_recognition = nil then
  begin
    showmessage( 'Cannot load face_recognition. ' + SysErrorMessage(GetLastError) );
    Halt;
  end;
  @_face_recognition_stream := GetProcAddress(DLibWrapperDLL, PChar('face_recognition_stream'));
  if @_face_recognition_stream = nil then
  begin
    showmessage( 'Cannot load face_recognition_stream. ' + SysErrorMessage(GetLastError) );
    Halt;
  end;
  @compare_face := GetProcAddress(DLibWrapperDLL, PChar('compare_face'));
  if @compare_face = nil then
  begin
    showmessage( 'Cannot load compare_face. ' + SysErrorMessage(GetLastError) );
    Halt;
  end;
  @release_face_locations := GetProcAddress(DLibWrapperDLL, PChar('release_face_locations'));
  if @release_face_locations = nil then
  begin
    showmessage( 'Cannot load release_face_locations. ' + SysErrorMessage(GetLastError) );
    Halt;
  end;
  @release_face_encodings := GetProcAddress(DLibWrapperDLL, PChar('release_face_encodings'));
  if @release_face_encodings = nil then
  begin
    showmessage( 'Cannot load release_face_encodings. ' + SysErrorMessage(GetLastError) );
    Halt;
  end;


finalization
  FreeLibrary(DLibWrapperDLL);
end.

