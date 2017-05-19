unit Argo;

interface

uses
  SysUtils, Classes, Variants;

type
  TJSONValueType = (jtString, jtBoolean, jtInt, jtDouble, jtArray, jtObject);
  TJSONObject = class;
  TJSONArray = class;

  TJSONValue = class(TObject)
    _t: TJSONValueType;
    _v: record
      case _valueType: TJSONValueType of
        jtString:  (s: PWideChar);
        jtBoolean: (b: Boolean);
        jtInt:     (i: Int64);
        jtDouble:  (d: Double);
        jtObject:  (o: TJSONObject);
        jtArray:   (a: TJSONArray);
    end;
    function ToString: string; override;
    constructor Create(_valueType: TJSONValueType); overload;
    destructor Destroy; override;
  end;

  TJSONArray = class(TObject)
  private
    Values: TList;
    function GetLength: Integer;
    function GetValue(index: Integer): TJSONValue;
    function MakeValue(index: Integer; _valueType: TJSONValueType): TJSONValue;
    function GetS(index: Integer): String;
    function GetB(index: Integer): Boolean;
    function GetI(index: Integer): Int64;
    function GetD(index: Integer): Double;
    function GetA(index: Integer): TJSONArray;
    function GetO(index: Integer): TJSONObject;
    procedure SetS(index: Integer; value: String);
    procedure SetB(index: Integer; value: Boolean);
    procedure SetI(index: Integer; value: Int64);
    procedure SetD(index: Integer; value: Double);
    procedure SetA(index: Integer; value: TJSONArray);
    procedure SetO(index: Integer; value: TJSONObject);
  public
    property Length: Integer read GetLength;
    property S[index: Integer]: String read GetS write SetS;
    property B[index: Integer]: Boolean read GetB write SetB;
    property I[index: Integer]: Int64 read GetI write SetI;
    property D[index: Integer]: Double read GetD write SetD;
    property O[index: Integer]: TJSONObject read GetO write SetO;
    property A[index: Integer]: TJSONArray read GetA write SetA;
    function Add(value: String): Integer; overload;
    function Add(value: Boolean): Integer; overload;
    function Add(value: Int64): Integer; overload;
    function Add(value: Double): Integer; overload;
    function Add(value: TJSONObject): Integer; overload;
    function Add(value: TJSONArray): Integer; overload;
    procedure Delete(index: Integer);
    function ToString: string; override;
    constructor Create;
    destructor Destroy; override;
  end;

  TJSONPair = class(TObject)
  private
    key: string;
    value: TJSONValue;
  public
    function ToString: string; override;
    constructor Create(key: string; _valueType: TJSONValueType); overload;
    destructor Destroy; override;
  end;

  TJSONObject = class(TObject)
  private
    Pairs: TList;
    function GetPair(key: string): TJSONPair;
    function MakePair(key: string; _valueType: TJSONValueType): TJSONPair;
    function GetS(key: string): String;
    function GetB(key: string): Boolean;
    function GetI(key: string): Int64;
    function GetD(key: string): Double;
    function GetA(key: string): TJSONArray;
    function GetO(key: string): TJSONObject;
    procedure SetS(key: string; value: String);
    procedure SetB(key: string; value: Boolean);
    procedure SetO(key: string; value: TJSONObject);
    procedure SetA(key: string; value: TJSONArray);
    procedure SetI(key: string; value: Int64);
    procedure SetD(key: string; value: Double);
  public
    property S[index: string]: String read GetS write SetS;
    property B[index: string]: Boolean read GetB write SetB;
    property I[index: string]: Int64 read GetI write SetI;
    property D[index: string]: Double read GetD write SetD;
    property O[index: string]: TJSONObject read GetO write SetO;
    property A[index: string]: TJSONArray read GetA write SetA;
    function HasKey(key: string): Boolean;
    procedure Delete(key: string);
    function ToString: string; override;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ HELPERS }

function StringSize(str: string): Integer;
begin
  Result := ByteLength(str);
  if Result > 0 then
    Inc(Result, 2 * (SizeOf(word) + SizeOf(Longint)) + SizeOf(Char));
end;

function AllocString(str: string): PWideChar;
var
  size: Integer;
begin
  size := StringSize(str);
  GetMem(Result, size);
  StrLCopy(Result, PWideChar(str), size);
end;

{ TJSONValue }
constructor TJSONValue.Create(_valueType: TJSONValueType);
begin
  _t := _valueType;
end;

destructor TJSONValue.Destroy;
begin
  if _t = jtArray then _v.a.Free;
  if _t = jtObject then _v.o.Free;
  inherited;
end;

function TJSONValue.ToString: String;
begin
  case _t of
    jtString: Result := '"' + _v.s + '"';
    jtBoolean: Result := BoolToStr(_v.b, true);
    jtInt: Result := IntToStr(_v.i);
    jtDouble: Result := FloatToStr(_v.d);
    jtArray: Result := _v.a.ToString;
    jtObject: Result := _v.o.ToString;
  end;
end;

{ TJSONArray }
constructor TJSONArray.Create;
begin
  Values := TList.Create;
end;

destructor TJSONArray.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(Values.Count) do
    TJSONValue(Values[i]).Free;
  Values.Free;
  inherited;
end;

function TJSONArray.GetLength: Integer;
begin
   Result := Values.Count;
end;

function TJSONArray.GetValue(index: Integer): TJSONValue;
begin
  Result := nil;
  if index < Values.Count then
    Result := TJSONValue(Values[index]);
end;

function TJSONArray.MakeValue(index: Integer; _valueType: TJSONValueType): TJSONValue;
begin
  Result := GetValue(index);
  if Assigned(Result) then
    Result._t := _valueType
  else begin
    Result := TJSONValue.Create(_valueType);
    Values.Add(Result);
  end;
end;

function TJSONArray.GetS(index: Integer): String;
var
  value: TJSONValue;
begin
  Result := '';
  value := GetValue(index);
  if Assigned(value) and (value._t = jtString) then
    Result := value._v.s;
end;

function TJSONArray.GetB(index: Integer): Boolean;
var
  value: TJSONValue;
begin
  Result := false;
  value := GetValue(index);
  if Assigned(value) and (value._t = jtBoolean) then
    Result := value._v.b;
end;

function TJSONArray.GetI(index: Integer): Int64;
var
  value: TJSONValue;
begin
  Result := 0;
  value := GetValue(index);
  if Assigned(value) and (value._t = jtInt) then
    Result := value._v.i;
end;

function TJSONArray.GetD(index: Integer): Double;
var
  value: TJSONValue;
begin
  Result := 0.0;
  value := GetValue(index);
  if Assigned(value) and (value._t = jtDouble) then
    Result := value._v.d;
end;

function TJSONArray.GetA(index: Integer): TJSONArray;
var
  value: TJSONValue;
begin
  Result := nil;
  value := GetValue(index);
  if Assigned(value) and (value._t = jtArray) then
    Result := value._v.a;
end;

function TJSONArray.GetO(index: Integer): TJSONObject;
var
  value: TJSONValue;
begin
  Result := nil;
  value := GetValue(index);
  if Assigned(value) and (value._t = jtObject) then
    Result := value._v.o;
end;

procedure TJSONArray.SetS(index: Integer; value: String);
begin
  MakeValue(index, jtString)._v.s := AllocString(value);
end;

procedure TJSONArray.SetB(index: Integer; value: Boolean);
begin
  MakeValue(index, jtBoolean)._v.b := value;
end;

procedure TJSONArray.SetI(index: Integer; value: Int64);
begin
  MakeValue(index, jtInt)._v.i := value;
end;

procedure TJSONArray.SetD(index: Integer; value: Double);
begin
  MakeValue(index, jtDouble)._v.d := value;
end;

procedure TJSONArray.SetA(index: Integer; value: TJSONArray);
begin
  MakeValue(index, jtArray)._v.a := value;
end;

procedure TJSONArray.SetO(index: Integer; value: TJSONObject);
begin
  MakeValue(index, jtObject)._v.o := value;
end;

function TJSONArray.Add(value: String): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtString);
  newValue._v.s := AllocString(value);
  Result := Values.Add(newValue);
end;

function TJSONArray.Add(value: Boolean): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtBoolean);
  newValue._v.b := value;
  Result := Values.Add(newValue);
end;

function TJSONArray.Add(value: Int64): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtInt);
  newValue._v.i := value;
  Result := Values.Add(newValue);
end;

function TJSONArray.Add(value: Double): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtDouble);
  newValue._v.d := value;
  Result := Values.Add(newValue);
end;

function TJSONArray.Add(value: TJSONArray): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtArray);
  newValue._v.a := value;
  Result := Values.Add(newValue);
end;

function TJSONArray.Add(value: TJSONObject): Integer;
var
  newValue: TJSONValue;
begin
  newValue := TJSONValue.Create(jtObject);
  newValue._v.o := value;
  Result := Values.Add(newValue);
end;

procedure TJSONArray.Delete(index: Integer);
begin
  if index < Values.Count then
    Values.Delete(index);
end;

function TJSONArray.ToString: String;
var
  i: Integer;
begin
  Result := '[';
  for i := 0 to Pred(Values.Count) do
    Result := Result + TJSONValue(Values[i]).ToString + ',';
  //Result[Length(Result)] := ']';
  Result := Result + ']';
end;

{ TJSONPair }
constructor TJSONPair.Create(key: string; _valueType: TJSONValueType);
begin
  self.key := key;
  value := TJSONValue.Create(_valueType);
end;

destructor TJSONPair.Destroy;
begin
  value.Free;
  inherited;
end;

function TJSONPair.ToString: string;
begin
  Result := '"' + key + '":' + Value.ToString;
end;

{ TJSONObject }
constructor TJSONObject.Create;
begin
  Pairs := TList.Create;
end;

destructor TJSONObject.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(Pairs.Count) do
    TJSONPair(Pairs[i]).Free;
  Pairs.Free;
  inherited;
end;

function TJSONObject.GetPair(key: string): TJSONPair;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Pred(Pairs.Count) do
    if TJSONPair(Pairs[i]).key = key then begin
      Result := TJSONPair(Pairs[i]);
      exit;
    end;
end;

function TJSONObject.GetS(key: string): string;
var
  pair: TJSONPair;
begin
  Result := '';
  pair := GetPair(key);
  if Assigned(pair) and (pair.Value._t = jtString) then
    Result := WideString(pair.Value._v.s);
end;

function TJSONObject.GetB(key: string): boolean;
var
  pair: TJSONPair;
begin
  Result := false;
  pair := GetPair(key);
  if Assigned(pair) and (pair.Value._t = jtBoolean) then
    Result := pair.Value._v.b;
end;

function TJSONObject.GetI(key: string): Int64;
var
  pair: TJSONPair;
begin
  Result := 0;
  pair := GetPair(key);
  if Assigned(pair) and (pair.value._t = jtInt) then
    Result := pair.value._v.i;
end;

function TJSONObject.GetD(key: string): Double;
var
  pair: TJSONPair;
begin
  Result := 0.0;
  pair := GetPair(key);
  if Assigned(pair) and (pair.Value._t = jtDouble) then
    Result := pair.Value._v.d;
end;

function TJSONObject.GetA(key: string): TJSONArray;
var
  pair: TJSONPair;
begin
  Result := nil;
  pair := GetPair(key);
  if Assigned(pair) and (pair.Value._t = jtArray) then
    Result := pair.Value._v.a;
end;

function TJSONObject.GetO(key: string): TJSONObject;
var
  pair: TJSONPair;
begin
  Result := nil;
  pair := GetPair(key);
  if Assigned(pair) and (pair.Value._t = jtObject) then
    Result := pair.Value._v.o;
end;

function TJSONObject.MakePair(key: string; _valueType: TJSONValueType): TJSONPair;
begin
  Result := GetPair(key);
  if Assigned(Result) then
    Result.Value._t := _valueType
  else begin
    Result := TJSONPair.Create(key, _valueType);
    Pairs.Add(Result);
  end;
end;

procedure TJSONObject.SetS(key: string; value: string);
begin
  MakePair(key, jtString).Value._v.s := AllocString(value);
end;

procedure TJSONObject.SetB(key: string; value: boolean);
begin
  MakePair(key, jtBoolean).Value._v.b := value;
end;

procedure TJSONObject.SetI(key: string; value: Int64);
begin
  MakePair(key, jtInt).Value._v.i := value;
end;

procedure TJSONObject.SetD(key: string; value: Double);
begin
  MakePair(key, jtDouble).Value._v.d := value;
end;

procedure TJSONObject.SetA(key: string; value: TJSONArray);
begin
  MakePair(key, jtArray).Value._v.a := value;
end;

procedure TJSONObject.SetO(key: string; value: TJSONObject);
begin
  MakePair(key, jtObject).Value._v.o := value;
end;

function TJSONObject.HasKey(key: string): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Pred(Pairs.Count) do
    if TJSONPair(Pairs[i]).key = key then begin
      Result := true;
      exit;
    end;
end;

procedure TJSONObject.Delete(key: string);
var
  i: Integer;
begin
  for i := Pred(Pairs.Count) downto 0 do
    if TJSONPair(Pairs[i]).key = key then begin
      Pairs.Delete(i);
      exit;
    end;
end;

function TJSONObject.ToString: String;
var
  i: Integer;
begin
  Result := '{';
  for i := 0 to Pred(Pairs.Count) do
    Result := Result + TJSONPair(Pairs[i]).ToString + ',';
  Result[Length(Result)] := '}';
end;

end.