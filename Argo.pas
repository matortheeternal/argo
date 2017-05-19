unit Argo;

interface

uses
  SysUtils, Classes, Variants;

type
  TJSONValueType = (jtString, jtBoolean, jtInt, jtDouble, jtArray, jtObject);
  JSONExceptionType = (jxEndOfStr, jxUnexpectedChar, jxStartBracket,
    jxColonExpected, jxCommaExpected, jxUnexpectedNumeric, jxUnrecognizedValue);

  JSONException = class(Exception)
  public
    constructor Create(exceptionType: JSONExceptionType; pos: PWideChar);
  end;

  TJSONObject = class;
  TJSONArray = class;

  TJSONValue = class(TObject)
  private
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
    procedure ParseObject(var P: PWideChar);
    procedure ParseArray(var P: PWideChar);
    procedure ParseString(var P: PWideChar);
    procedure ParseBoolean(var P: PWideChar);
    procedure ParseNumeric(var P: PWideChar);
  public
    constructor Create(_valueType: TJSONValueType); overload;
    constructor Create(var P: PWideChar); overload;
    destructor Destroy; override;
    function ToString: string; override;
  end;

  TJSONArray = class(TObject)
  private
    Values: TList;
    function GetCount: Integer;
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
    constructor Create; overload;
    constructor Create(var P: PWideChar); overload;
    destructor Destroy; override;
    procedure Delete(index: Integer);
    function ToString: string; override;
    property Count: Integer read GetCount;
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
  end;

  TJSONObject = class(TObject)
  private
    Pairs: TStringList;
    procedure ParseObject(var P: PWideChar);
    procedure ParsePair(var P: PWideChar);
    function GetValue(key: string): TJSONValue;
    function MakeValue(key: string; _valueType: TJSONValueType): TJSONValue;
    function GetKey(index: Integer): String;
    function GetCount: Integer;
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
    constructor Create; overload;
    constructor Create(json: string); overload;
    destructor Destroy; override;
    function HasKey(key: string): Boolean;
    procedure Delete(key: string);
    function ToString: string; override;
    property Keys[index: Integer]: String read GetKey;
    property Count: Integer read GetCount;
    property S[index: string]: String read GetS write SetS;
    property B[index: string]: Boolean read GetB write SetB;
    property I[index: string]: Int64 read GetI write SetI;
    property D[index: string]: Double read GetD write SetD;
    property O[index: string]: TJSONObject read GetO write SetO;
    property A[index: string]: TJSONArray read GetA write SetA;
  end;

  // HELPER FUNCTIONS
  // TODO


implementation

{ === HELPERS === }

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

{ === DESERIALIZATION === }

var
  ParseStart: Pointer;
  LastToken: Boolean;

// function should be entered on the opening double quote for a JSON string.
function ParseJSONString(var P: PWideChar): String;
var
  escaped: Boolean;
  c: WideChar;
begin
  Result := '';
  escaped := false;
  while true do begin
    Inc(P);
    c := P^;
    case c of
      '\': // backslash
        escaped := true;
      '"': // quote
        if not escaped then break;
      #0:
        raise JSONException.Create(jxEndOfStr, P);
      else begin
        if ord(c) < 32 then
          raise JSONException.Create(jxUnexpectedChar, P)
        else
          Result := Result + c;
      end;
    end;
  end;
  Inc(P); // move past trailing quote
end;

// function should be entered between object or array members
function ParseSeparation(var P: PWideChar; separator: AnsiChar): Boolean;
begin
  Result := False;
  // iterate over whitespace and separators
  while CharInSet(P^, [#10, #13, ' ', separator]) do begin
    if P^ = ',' then begin
      // duplicate separators raise an exception
      if Result then
        raise JSONException.Create(jxUnexpectedChar, P);
      Result := True;
    end;
    Inc(P);
  end;
end;

{ JSONException }
constructor JSONException.Create(exceptionType: JSONExceptionType; pos: PWideChar);
const
  JSONExceptionMessages: array[0..6] of string = (
    'Unexpected end of JSON string at position %d.',
    'Unexpected character in JSON string at position %d.',
    'Expected left brace to start object at position %d.',
    'Expected colon separating key value pair at position %d.',
    'Expected comma separating object members at position %d.',
    'Unexpected character in numeric value at position %d.',
    'Unrecognized value at position %d.'
  );
var
  strPos: Integer;
begin
  strPos := ParseStart - pos;
  self.Message := Format(JSONExceptionMessages[Ord(exceptionType)], [strPos]);
end;

{ TJSONObject Deserialization }
constructor TJSONObject.Create(json: string);
var
  P: PWideChar;
begin
  Pairs := TStringList.Create;
  ParseStart := @json;
  LastToken := False;
  P := PWideChar(json);
  ParseObject(P);
end;

procedure TJSONObject.ParseObject(var P: PWideChar);
var
  c: WideChar;
begin
  if P^ <> '{' then
    raise JSONException.Create(jxStartBracket, P);
  while true do begin
    Inc(P);
    c := P^;
    case c of
      #13, #10, ' ': // whitespace characters
        continue;
      '"':
        if LastToken then
          raise JSONException.Create(jxCommaExpected, P)
        else
          ParsePair(P);
      '}':
        break;
      #0:
        raise JSONException.Create(jxEndOfStr, P);
      else
        raise JSONException.Create(jxUnexpectedChar, P);
    end;
  end;
  // reset token separation tracking
  LastToken := False;
end;

procedure TJSONObject.ParsePair(var P: PWideChar);
var
  key: string;
  value: TJSONValue;
begin
  key := ParseJSONString(P);
  if not ParseSeparation(P, ':') then
    raise JSONException.Create(jxColonExpected, P);
  value := TJSONValue.Create(P);
  Pairs.AddObject(key, value);
  if not ParseSeparation(P, ',') then
    LastToken := true;
end;

{ TJSONArray Deserialization }
constructor TJSONArray.Create(var P: PWideChar);
var
  c: WideChar;
begin
  while true do begin
    Inc(P);
    c := P^;
    case c of
      #13, #10, ' ': // whitespace characters
        continue;
      ']':
        break;
      #0:
        raise JSONException.Create(jxEndOfStr, P);
      else begin
        Values.Add(TJSONValue.Create(P));
        if not ParseSeparation(P, ',') then
          LastToken := true;
      end;
    end;
  end;
  // reset token separation tracking
  LastToken := False;
end;

{ TJSONValue Deserialization }
constructor TJSONValue.Create(var P: PWideChar);
begin
  case P^ of
    '[': ParseObject(P);
    '{': ParseArray(P);
    '"': ParseString(P);
    'f','t','F','T': ParseBoolean(P);
    else ParseNumeric(P);
  end;
end;

procedure TJSONValue.ParseString(var P: PWidechar);
begin
  _t := jtString;
  _v.s := PWideChar(ParseJSONString(P));
end;

procedure TJSONValue.ParseBoolean(var P: PWidechar);
begin
  _t := jtBoolean;
  if StrLIComp(P, 'true', 4) = 0 then begin
    _v.b := true;
    Inc(P, 4);
  end
  else if StrLIComp(P, 'false', 5) = 0 then begin
    _v.b := false;
    Inc(P, 5);
  end
  else
    raise JSONException.Create(jxUnrecognizedValue, P);
end;

procedure TJSONValue.ParseNumeric(var P: PWidechar);
var
  str: String;
  c: WideChar;
begin
  _t := jtInt;
  str := '';
  while true do begin
    c := P^;
    case c of
      #10, #13, ' ', ',': break;
      '.': begin
        _t := jtDouble;
        str := str + c;
      end;
      else begin
        if CharInSet(c, ['0'..'9','+','-','e','E']) then
          str := str + c
        else
          raise JSONException.Create(jxUnexpectedNumeric, P);
      end;
    end;
    Inc(P);
  end;
  if _t = jtDouble then
    _v.d := StrToFloat(str)
  else
    _v.i := StrToInt(str);
end;

procedure TJSONValue.ParseArray(var P: PWidechar);
begin
  _t := jtArray;
  _v.a := TJSONArray.Create(P);
end;

procedure TJSONValue.ParseObject(var P: PWidechar);
begin
  _t := jtObject;
  _v.o := TJSONObject.Create;
  _v.o.ParseObject(P);
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

{ === GENERAL === }

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

function TJSONArray.GetCount: Integer;
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

function TJSONArray.ToString: string;
var
  i: Integer;
begin
  Result := '[';
  for i := 0 to Pred(Values.Count) do
    Result := Result + TJSONValue(Values[i]).ToString + ',';
  if Values.Count > 0 then
    SetLength(Result, Length(Result) - 1);
  Result := Result + ']';
end;

{ TJSONObject }
constructor TJSONObject.Create;
begin
  Pairs := TStringList.Create;
end;

destructor TJSONObject.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(Pairs.Count) do
    TJSONValue(Pairs.Objects[i]).Free;
  Pairs.Free;
  inherited;
end;

function TJSONObject.GetValue(key: string): TJSONValue;
var
  i: Integer;
begin
  Result := nil;
  i := Pairs.IndexOf(key);
  if i > -1 then
    Result := TJSONValue(Pairs.Objects[i]);
end;

function TJSONObject.GetS(key: string): string;
var
  value: TJSONValue;
begin
  Result := '';
  value := GetValue(key);
  if Assigned(value) and (value._t = jtString) then
    Result := WideString(value._v.s);
end;

function TJSONObject.GetB(key: string): boolean;
var
  value: TJSONValue;
begin
  Result := false;
  value := GetValue(key);
  if Assigned(value) and (value._t = jtBoolean) then
    Result := value._v.b;
end;

function TJSONObject.GetI(key: string): Int64;
var
  value: TJSONValue;
begin
  Result := 0;
  value := GetValue(key);
  if Assigned(value) and (value._t = jtInt) then
    Result := value._v.i;
end;

function TJSONObject.GetD(key: string): Double;
var
  value: TJSONValue;
begin
  Result := 0.0;
  value := GetValue(key);
  if Assigned(value) and (value._t = jtDouble) then
    Result := value._v.d;
end;

function TJSONObject.GetA(key: string): TJSONArray;
var
  value: TJSONValue;
begin
  Result := nil;
  value := GetValue(key);
  if Assigned(value) and (value._t = jtArray) then
    Result := value._v.a;
end;

function TJSONObject.GetO(key: string): TJSONObject;
var
  value: TJSONValue;
begin
  Result := nil;
  value := GetValue(key);
  if Assigned(value) and (value._t = jtObject) then
    Result := value._v.o;
end;

function TJSONObject.MakeValue(key: string; _valueType: TJSONValueType): TJSONValue;
begin
  Result := GetValue(key);
  if Assigned(Result) then
    Result._t := _valueType
  else begin
    Result := TJSONValue.Create(_valueType);
    Pairs.AddObject(key, Result);
  end;
end;

function TJSONObject.GetKey(index: Integer): string;
begin
  Result := Pairs[index];
end;

function TJSONObject.GetCount: Integer;
begin
  Result := Pairs.Count;
end;

procedure TJSONObject.SetS(key: string; value: string);
begin
  MakeValue(key, jtString)._v.s := AllocString(value);
end;

procedure TJSONObject.SetB(key: string; value: boolean);
begin
  MakeValue(key, jtBoolean)._v.b := value;
end;

procedure TJSONObject.SetI(key: string; value: Int64);
begin
  MakeValue(key, jtInt)._v.i := value;
end;

procedure TJSONObject.SetD(key: string; value: Double);
begin
  MakeValue(key, jtDouble)._v.d := value;
end;

procedure TJSONObject.SetA(key: string; value: TJSONArray);
begin
  MakeValue(key, jtArray)._v.a := value;
end;

procedure TJSONObject.SetO(key: string; value: TJSONObject);
begin
  MakeValue(key, jtObject)._v.o := value;
end;

function TJSONObject.HasKey(key: string): Boolean;
begin
  Result := Pairs.IndexOf(key) > -1;
end;

procedure TJSONObject.Delete(key: string);
var
  i: Integer;
begin
  i := Pairs.IndexOf(key);
  if i > -1 then
    Pairs.Delete(i);
end;

function TJSONObject.ToString: String;
var
  i: Integer;
begin
  Result := '{';
  for i := 0 to Pred(Pairs.Count) do
    Result := Result + '"' + Pairs[i] + '":' + TJSONValue(Pairs.Objects[i]).ToString + ',';
  if Pairs.Count > 0 then
    SetLength(Result, Length(Result) - 1);
  Result := Result + '}';
end;

end.