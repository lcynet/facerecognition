{
  This demo needs the following files in the same directory as the Project1.exe:
  bald_guys.jpg ... is originally from the dlib.net library
  dlibwrapper32bit.dll ... for 32bit
  dlibwrapper64bit.dll ... for 64bit
  dlib_face_recognition_resnet_model_v1.dat ... can downloaded from "http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2" and unpack it
  shape_predictor_5_face_landmarks.dat ... can downloaded from "http://dlib.net/files/shape_predictor_5_face_landmarks.dat.bz2" and unpack it
}

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FaceRecognition, ActiveX, Jpeg;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;


implementation

{$R *.dfm}

uses
  Unit2;

procedure TForm1.Button1Click(Sender: TObject);
var
  filename: String;
  face_locations: ar_face_locations;
  face_encodings: _ar_face_encodings;
  i: Integer;
  j: Integer;
  distance: Single;
  bmp_temp: TBitmap;
  similiar_faces: array of integer;
  ms: TMemorystream;
  StreamForDLL: IStream;
begin
  filename := Edit1.Text;
  Form2.Image1.Picture.LoadFromFile(filename);
  Form2.Image1.Width := Form2.Image1.Picture.Width;
  Form2.Image1.Height := Form2.Image1.Picture.Height;

  Form2.Width := Form2.Image1.Width;
  Form2.Height := Form2.Image1.Height;

  bmp_temp := TBitmap.Create;
  try
    bmp_temp.Assign( Form2.Image1.Picture.Graphic );
    Form2.Image1.Picture.Bitmap.Assign( bmp_temp );

    ms := TMemoryStream.Create;
    bmp_temp.SaveToStream( ms );
    ms.Position := 0;
    StreamForDLL := TStreamAdapter.Create( ms, soOwned );

    face_recognition_stream( StreamForDLL, face_locations, face_encodings );
  finally
    bmp_temp.Free;
  end;
 
  Memo1.Clear;

  for I := 0 to Length(face_locations) - 1 do
  begin
    Memo1.Lines.Add( '------------------------------------------' );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_top:' + intToStr( face_locations[i].face_location_top ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_left:' + intToStr( face_locations[i].face_location_left ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_bottom:' + intToStr( face_locations[i].face_location_bottom ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_right:' + intToStr( face_locations[i].face_location_right ) );
  end;

  for I := 0 to Length(face_locations) - 1 do
  begin
    for j := 0 to 128 - 1 do
    begin
      Memo1.Lines.Add( 'face_encodings[' + IntToStr(i) + '][' + IntToStr(j) + ']:' + FloatToStr( face_encodings[i][j] ) );
    end;
  end;

  Form2.Image1.Picture.LoadFromFile(filename);
  Form2.Image1.Width := Form2.Image1.Picture.Width;
  Form2.Image1.Height := Form2.Image1.Picture.Height;

  bmp_temp:=TBitmap.Create;
  try
    bmp_temp.Assign( Form2.Image1.Picture.Graphic);
    Form2.Image1.Picture.Bitmap.Assign(bmp_temp);
  finally
    bmp_temp.Free;
  end;

  for I := 0 to Length(face_locations) - 1 do
  begin
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Color := clWhite;
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Width := 2;
    Form2.Image1.Picture.Bitmap.Canvas.Brush.Style := bsClear;
    Form2.Image1.Picture.Bitmap.Canvas.Rectangle( face_locations[i].face_location_left, face_locations[i].face_location_top, face_locations[i].face_location_right, face_locations[i].face_location_bottom );
    Form2.Image1.Picture.Bitmap.Canvas.Font.Color := clWhite;
    Form2.Image1.Picture.Bitmap.Canvas.Font.Size := 30;
    Form2.Image1.Picture.Bitmap.Canvas.TextOut(face_locations[i].face_location_left, face_locations[i].face_location_top, IntToStr(i));
  end;
  Memo1.Lines.Add( '------------------------------------------' );

  //compare face_encoding[0] with other faces
  SetLength( similiar_faces, 0 );
  for i := 0 to Length( face_encodings ) - 1 do
  begin
    compare_face( face_encodings[0], face_encodings[i], Distance ); // <------ you can choose another Source value like face_encodings[1] or face_encodings[4] for Bruce Wills and see what happens ;-)
    if distance < 0.6 then
    begin
      Memo1.Lines.Add( 'Face[0] and Face['+IntToStr(i)+'] is very similiar ' );
      SetLength(similiar_faces, Length(similiar_faces)+1);
      similiar_faces[high(similiar_faces)] := i;
    end;
  end;

  // draw red retangle on simliar faces
  for I := 0 to Length(similiar_faces) - 1 do
  begin
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Color := clRed;
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Width := 5;
    Form2.Image1.Picture.Bitmap.Canvas.Brush.Style := bsClear;
    Form2.Image1.Picture.Bitmap.Canvas.Rectangle( face_locations[similiar_faces[i]].face_location_left, face_locations[similiar_faces[i]].face_location_top, face_locations[similiar_faces[i]].face_location_right, face_locations[similiar_faces[i]].face_location_bottom );
    Form2.Image1.Picture.Bitmap.Canvas.Font.Color := clRed;
    Form2.Image1.Picture.Bitmap.Canvas.Font.Size := 30;
    Form2.Image1.Picture.Bitmap.Canvas.TextOut(face_locations[similiar_faces[i]].face_location_left, face_locations[similiar_faces[i]].face_location_top, IntToStr(similiar_faces[i]));
  end;
  Form2.Image1.Refresh;
  Form2.Show;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  fr: IFaceRecognition;
  filename: WideString;
  i: Integer;
  j: Integer;
  face_locations: ar_face_locations;
  face_encodings: _ar_face_encodings;
  Distance: Single;
  bmp_temp:TBitmap;
  similiar_faces: array of integer;
  ms: TMemorystream;
  StreamForDLL: IStream;
begin
  fr := TFaceRecognition.Create;
  filename := Edit1.Text;

  Form2.Image1.Picture.LoadFromFile(filename);
  Form2.Image1.Width := Form2.Image1.Picture.Width;
  Form2.Image1.Height := Form2.Image1.Picture.Height;

  Form2.Width := Form2.Image1.Width;
  Form2.Height := Form2.Image1.Height;

  bmp_temp:=TBitmap.Create;
  try
    bmp_temp.Assign( Form2.Image1.Picture.Graphic);
    Form2.Image1.Picture.Bitmap.Assign(bmp_temp);

    ms := TMemoryStream.Create;
    bmp_temp.SaveToStream(ms);
    ms.Position := 0;
    StreamForDLL := TStreamAdapter.Create(ms, soOwned);

    fr.LoadImageStream (StreamForDLL);
  finally
    bmp_temp.Free;
  end;
  
  Memo1.Clear;

  fr.FaceLocations( face_locations ); //getting face locations

  for i := 0 to Length( face_locations ) - 1 do
  begin
    Memo1.Lines.Add( '------------------------------------------' );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_top:' + intToStr( face_locations[i].face_location_top ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_left:' + intToStr( face_locations[i].face_location_left ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_bottom:' + intToStr( face_locations[i].face_location_bottom ) );
    Memo1.Lines.Add( 'fl[' + IntToStr(i) + '].face_location_right:' + intToStr( face_locations[i].face_location_right ) );
  end;

  fr.FaceEncodings(face_encodings);

  for i := 0 to Length( face_locations ) - 1 do
  begin
    for j := 0 to 128 - 1 do
    begin
      Memo1.Lines.Add( 'face_encodings[' + IntToStr(i) + '][' + IntToStr(j) + ']:' + FloatToStr( face_encodings[i][j] ) );
    end;
  end;

  // draw white retangle on all faces
  for I := 0 to Length(face_locations) - 1 do
  begin
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Color := clWhite;
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Width := 2;
    Form2.Image1.Picture.Bitmap.Canvas.Brush.Style := bsClear;
    Form2.Image1.Picture.Bitmap.Canvas.Rectangle( face_locations[i].face_location_left, face_locations[i].face_location_top, face_locations[i].face_location_right, face_locations[i].face_location_bottom );
    Form2.Image1.Picture.Bitmap.Canvas.Font.Color := clWhite;
    Form2.Image1.Picture.Bitmap.Canvas.Font.Size := 30;
    Form2.Image1.Picture.Bitmap.Canvas.TextOut(face_locations[i].face_location_left, face_locations[i].face_location_top, IntToStr(i));
  end;
  Memo1.Lines.Add( '------------------------------------------' );

  //compare face_encoding[0] with other faces
  SetLength(similiar_faces, 0);
  for i := 0 to Length(face_encodings) - 1 do
  begin
    compare_face(face_encodings[0], face_encodings[i], Distance); // <------ you can choose another source value than "face_encodings[0]" like "face_encodings[1]" or "face_encodings[4]" for Bruce Wills and see what happens ;-)
    if distance < 0.6 then
    begin
      Memo1.Lines.Add( 'Face[0] and Face['+IntToStr(i)+'] is very similiar ' );
      SetLength(similiar_faces, Length(similiar_faces)+1);
      similiar_faces[high(similiar_faces)] := i;
    end;
  end;

  // draw red retangle on simliar faces
  for I := 0 to Length( similiar_faces ) - 1 do
  begin
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Color := clRed;
    Form2.Image1.Picture.Bitmap.Canvas.Pen.Width := 5;
    Form2.Image1.Picture.Bitmap.Canvas.Brush.Style := bsClear;
    Form2.Image1.Picture.Bitmap.Canvas.Rectangle( face_locations[ similiar_faces[i] ].face_location_left, face_locations[ similiar_faces[i] ].face_location_top, face_locations[ similiar_faces[i] ].face_location_right, face_locations[ similiar_faces[i] ].face_location_bottom );
    Form2.Image1.Picture.Bitmap.Canvas.Font.Color := clRed;
    Form2.Image1.Picture.Bitmap.Canvas.Font.Size := 30;
    Form2.Image1.Picture.Bitmap.Canvas.TextOut( face_locations[ similiar_faces[i] ].face_location_left, face_locations[ similiar_faces[i] ].face_location_top, IntToStr( similiar_faces[i] ) );
  end;
  Form2.Image1.Refresh;
  Form2.Show;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Edit1.Text := 'bald_guys.jpg';
end;

end.
