program ArgoTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Mahogany in 'lib\Mahogany\Mahogany.pas',
  Argo in 'Argo.pas';

procedure BuildMahoganyTests;
var
  obj: TJSONObject;
  ary: TJSONArray;
  P: PWideChar;
  json: String;
  h: Integer;
  i: Integer;
begin
  Describe('JSONArray', procedure
    begin
      BeforeAll(procedure
        begin
          i := 0;
        end);

      It('Constructor should work', procedure
        begin
          ary := TJSONArray.Create;
        end, true);

      Describe('String values', procedure
        begin
          It('Out of bounds indices should return an empty string', procedure
            begin
              ExpectEqual(ary.S[i], '', '');
            end);

          It('Should be able to add string values', procedure
            begin
              ary.Add('Testing');
            end);

          It('Should be able to retrieve string values', procedure
            begin
              ExpectEqual(ary.S[i], 'Testing');
            end);

          It('Should be able to replace string values', procedure
            begin
              ary.S[0] := 'abc';
              ExpectEqual(ary.S[i], 'abc');
            end);
        end);

      Describe('Boolean values', procedure
        begin
          It('Out of bounds indices should return False', procedure
            begin
              Inc(i);
              ExpectEqual(ary.B[i], 0);
            end);

          It('Should be able to add boolean values', procedure
            begin
              ary.Add(True);
            end);

          It('Should be able to retrieve boolean values', procedure
            begin
              ExpectEqual(ary.B[i], True);
            end);

          It('Should be able to replace boolean values', procedure
            begin
              ary.B[i] := False;
              ExpectEqual(ary.B[i], False);
            end);
        end);

      Describe('Integer values', procedure
        begin
          It('Out of bounds indices should return 0', procedure
            begin
              Inc(i);
              ExpectEqual(ary.I[i], 0);
            end);

          It('Should be able to add integer values', procedure
            begin
              ary.Add(5647382910);
            end);

          It('Should be able to retrieve integer values', procedure
            begin
              ExpectEqual(ary.I[i], 5647382910);
            end);

          It('Should be able to replace integer values', procedure
            begin
              ary.I[i] := -1029384756;
              ExpectEqual(ary.I[i], -1029384756);
            end);
        end);

      Describe('Double values', procedure
        begin
          It('Out of bounds indices should return 0.0', procedure
            begin
              Inc(i);
              ExpectEqual(ary.D[i], 0.0);
            end);

          It('Should be able to add double values', procedure
            begin
              ary.Add(1.414213562);
            end);

          It('Should be able to retrieve double values', procedure
            begin
              ExpectEqual(ary.D[i], 1.414213562);
            end);

          It('Should be able to replace double values', procedure
            begin
              ary.D[i] := -2.71828182845;
              ExpectEqual(ary.D[i], -2.71828182845);
            end);
        end);

      Describe('Array values', procedure
        begin
          It('Out of bounds indices should return nil', procedure
            begin
              Inc(i);
              Expect(not Assigned(ary.A[i]));
            end);

          It('Should be able to add array values', procedure
            begin
              ary.Add(TJSONArray.Create);
            end);

          It('Should be able to retrieve array values', procedure
            begin
              h := ary.A[i].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace array values', procedure
            begin
              ary.A[i] := TJSONArray.Create;
              Expect(ary.A[i].GetHashCode <> h);
            end);
        end);

      Describe('Object values', procedure
        begin
          It('Out of bounds indices should return nil', procedure
            begin
              Inc(i);
              Expect(not Assigned(ary.O[i]));
            end);

          It('Should be able to add object values', procedure
            begin
              ary.Add(TJSONObject.Create);
            end);

          It('Should be able to retrieve object values', procedure
            begin
              h := ary.O[i].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace object values', procedure
            begin
              ary.O[i] := TJSONObject.Create;
              Expect(ary.O[i].GetHashCode <> h);
            end);
        end);

      Describe('Serialization', procedure
        begin
          BeforeAll(procedure
            begin
              json := ary.ToString;
            end);

          It('Should serialize object bounds', procedure
            begin
              ExpectEqual(json[1], '[');
              ExpectEqual(json[Length(json)], ']');
            end);

          It('Should serialize string values correctly', procedure
            begin
              Expect(Pos('"abc"', json) > 0, 'Should contain "abc"');
            end);

          It('Should serialize boolean values correctly', procedure
            begin
              Expect(Pos('False', json) > 0, 'Should contain False');
            end);

          It('Should serialize integer values correctly', procedure
            begin
              Expect(Pos('-1029384756', json) > 0, 'Should contain -1029384756');
            end);

          It('Should serialize double values correctly', procedure
            begin
              Expect(Pos('-2.71828182845', json) > 0, 'Should contain -2.71828182845');
            end);

          It('Should serialize array values correctly', procedure
            begin
              Expect(Pos('[]', json) > 0, 'Should contain []');
            end);

          It('Should serialize object values correctly', procedure
            begin
              Expect(Pos('{}', json) > 0, 'Should contain {}');
            end);
        end);

      Describe('Deserialization', procedure
        begin
          BeforeAll(procedure
            begin
              P := PWideChar(json);
              ary := TJSONArray.Create(P);
            end);

          It('Should deserialize the correct number of values', procedure
            begin
              ExpectEqual(ary.Count, 6);
            end);

          It('Should deserialize string values correctly', procedure
            begin
              ExpectEqual(ary.S[0], 'abc');
            end);

          It('Should deserialize boolean values correctly', procedure
            begin
              ExpectEqual(ary.B[1], False);
            end);

          It('Should deserialize integer values correctly', procedure
            begin
              ExpectEqual(ary.I[2], -1029384756);
            end);

          It('Should deserialize double values correctly', procedure
            begin
              ExpectEqual(ary.D[3], -2.71828182845);
            end);

          It('Should deserialize array values correctly', procedure
            begin
              Expect(ary.A[4].GetHashCode > 0);
            end);

          It('Should deserialize object values correctly', procedure
            begin
              Expect(ary.O[5].GetHashCode > 0);
            end);
        end);
    end);

  Describe('JSONObject', procedure
    begin
      It('Constructor should work', procedure
        begin
          obj := TJSONObject.Create;
        end, true);

      Describe('String values', procedure
        begin
          It('Unassigned keys should return an empty string', procedure
            begin
              ExpectEqual(obj.S['string'], '');
            end);

          It('Should be able to set string values', procedure
            begin
              obj.S['string'] := 'Testing';
            end);

          It('Should be able to retrieve string values', procedure
            begin
              ExpectEqual(obj.S['string'], 'Testing');
            end);

          It('Should be able to replace string values', procedure
            begin
              obj.S['string'] := 'abc';
              ExpectEqual(obj.S['string'], 'abc');
            end);
        end);

      Describe('Boolean values', procedure
        begin
          It('Unassigned keys should return false', procedure
            begin
              ExpectEqual(obj.B['string'], false);
            end);

          It('Should be able to set boolean values', procedure
            begin
              obj.B['boolean'] := true;
            end);

          It('Should be able to retrieve boolean values', procedure
            begin
              ExpectEqual(obj.B['boolean'], true);
            end);

          It('Should be able to replace boolean values', procedure
            begin
              obj.B['boolean'] := false;
              ExpectEqual(obj.B['boolean'], false);
            end);
        end);

      Describe('Integer values', procedure
        begin
          It('Unassigned keys should return 0', procedure
            begin
              ExpectEqual(obj.I['integer'], 0);
            end);

          It('Should be able to set integer values', procedure
            begin
              obj.I['integer'] := 1234567890;
            end);

          It('Should be able to retrieve integer values', procedure
            begin
              ExpectEqual(obj.I['integer'], 1234567890);
            end);

          It('Should be able to replace integer values', procedure
            begin
              obj.I['integer'] := -987654321;
              ExpectEqual(obj.I['integer'], -987654321);
            end);
        end);

      Describe('Double values', procedure
        begin
          It('Unassigned keys should return 0.0', procedure
            begin
              ExpectEqual(obj.D['double'], 0.0);
            end);

          It('Should be able to set double values', procedure
            begin
              obj.D['double'] := 1.618033;
            end);

          It('Should be able to retrieve double values', procedure
            begin
              ExpectEqual(obj.D['double'], 1.618033);
            end);

          It('Should be able to replace double values', procedure
            begin
              obj.D['double'] := -3.14159;
              ExpectEqual(obj.D['double'], -3.14159);
            end);
        end);

      Describe('Array values', procedure
        begin
          It('Unassigned keys should return nil', procedure
            begin
              Expect(not Assigned(obj.A['array']));
            end);

          It('Should be able to set array values', procedure
            begin
              obj.A['array'] := TJSONArray.Create;
            end);

          It('Should be able to retrieve array values', procedure
            begin
              h := obj.A['array'].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace array values', procedure
            begin
              obj.A['array'] := TJSONArray.Create;
              Expect(obj.A['array'].GetHashCode <> h, 'Hash codes should not match');
            end);
        end);

      Describe('Object values', procedure
        begin
          It('Unassigned keys should return nil', procedure
            begin
              Expect(not Assigned(obj.O['object']));
            end);

          It('Should be able to set object values', procedure
            begin
              obj.O['object'] := TJSONObject.Create;
            end);

          It('Should be able to retrieve object values', procedure
            begin
              h := obj.O['object'].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace object values', procedure
            begin
              obj.O['object'] := TJSONObject.Create;
              Expect(obj.O['object'].GetHashCode <> h, 'Hash codes should not match');
            end);
        end);

      Describe('Serialization', procedure
        begin
          BeforeAll(procedure
            begin
              json := obj.ToString;
            end);

          It('Should serialize object bounds', procedure
            begin
              ExpectEqual(json[1], '{');
              ExpectEqual(json[Length(json)], '}');
            end);

          It('Should serialize keys', procedure
            begin
              Expect(Pos('"string":', json) > 0, 'Should contain key "string"');
              Expect(Pos('"boolean":', json) > 0, 'Should contain key "boolaen"');
              Expect(Pos('"integer":', json) > 0, 'Should contain key "integer"');
              Expect(Pos('"double":', json) > 0, 'Should contain key "double"');
              Expect(Pos('"array":', json) > 0, 'Should contain key "array"');
              Expect(Pos('"object":', json) > 0, 'Should contain key "object"');
            end);

          It('Should serialize string values correctly', procedure
            begin
              Expect(Pos('"string":"abc"', json) > 0, 'Should contain "string":"abc"');
            end);

          It('Should serialize boolean values correctly', procedure
            begin
              Expect(Pos('"boolean":False', json) > 0, 'Should contain "boolean":False');
            end);

          It('Should serialize integer values correctly', procedure
            begin
              Expect(Pos('"integer":-987654321', json) > 0, 'Should contain "integer":-987654321');
            end);

          It('Should serialize double values correctly', procedure
            begin
              Expect(Pos('"double":-3.14159', json) > 0, 'Should contain "double":-3.14159');
            end);

          It('Should serialize array values correctly', procedure
            begin
              Expect(Pos('"array":[]', json) > 0, 'Should contain "array":[]');
            end);

          It('Should serialize object values correctly', procedure
            begin
              Expect(Pos('"object":{}', json) > 0, 'Should contain "object":{}');
            end);

          It('Should preserve field order from assignment', procedure
            begin
              Expect(Pos('"string":', json) < Pos('"boolean":', json), 'Should serialize string before boolean');
              Expect(Pos('"boolean":', json) < Pos('"integer":', json), 'Should serialize boolean before integer');
              Expect(Pos('"integer":', json) < Pos('"double":', json), 'Should serialize integer before double');
              Expect(Pos('"double":', json) < Pos('"array":', json), 'Should serialize double before array');
              Expect(Pos('"array":', json) < Pos('"object":', json), 'Should serialize array before object');
            end);
        end);

      Describe('Pairs', procedure
        begin
          It('Should allow you access pairs count', procedure
            begin
              ExpectEqual(obj.Count, 6);
            end);

          It('Should allow you to access pair keys by index', procedure
            begin
              ExpectEqual(obj.Keys[0], 'string');
              ExpectEqual(obj.Keys[1], 'boolean');
              ExpectEqual(obj.Keys[2], 'integer');
              ExpectEqual(obj.Keys[3], 'double');
              ExpectEqual(obj.Keys[4], 'array');
              ExpectEqual(obj.Keys[5], 'object');
            end);

          It('Should raise an exception if key index is out of bounds', procedure
            begin
              ExpectException(procedure
                begin
                  obj.Keys[6]
                end, 'List index out of bounds (6)');
            end);
        end);

      Describe('Deserialization', procedure
        begin
          BeforeAll(procedure
            begin
              obj := TJSONObject.Create(json);
            end);

          It('Should deserialize the correct number of pairs', procedure
            begin
              ExpectEqual(obj.Count, 6);
            end);

          It('Should deserialize string values correctly', procedure
            begin
              ExpectEqual(obj.S['string'], 'abc');
            end);

          It('Should deserialize boolean values correctly', procedure
            begin
              ExpectEqual(obj.B['boolean'], False);
            end);

          It('Should deserialize integer values correctly', procedure
            begin
              ExpectEqual(obj.I['integer'], -987654321);
            end);

          It('Should deserialize double values correctly', procedure
            begin
              ExpectEqual(obj.D['double'], -3.14159);
            end);

          It('Should deserialize array values correctly', procedure
            begin
              Expect(obj.A['array'].GetHashCode > 0);
            end);

          It('Should deserialize object values correctly', procedure
            begin
              Expect(obj.O['object'].GetHashCode > 0);
            end);
        end);
    end);

  Describe('Exceptions', procedure
    begin
      Describe('jxTerminated', procedure
        begin
          It('Should be raised when JSON object terminates unexpectedly', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"test":{');
                end, 'Unexpected end of JSON near <"test":{>.');
            end);

          It('Should be raised when JSON string terminates unexpectedly', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"cheese":"abc 123 ');
                end, 'Unexpected end of JSON near <abc 123 >.');
            end);

          It('Should be raised when JSON array terminates unexpectedly', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"open array": [40, "thousand",');
                end, 'Unexpected end of JSON near <ousand",>.');
            end);
        end);

      Describe('jxUnexpectedChar', procedure
        begin
          It('Should be raised when JSON object has unquoted key', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"test":{a:True}}');
                end, 'Unexpected character in JSON near <"test":{a:True}}>.');
            end);

          It('Should be raised when using an invalid JSON value', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"test":{"a":nil}}');
                end, 'Unexpected character in JSON near <t":{"a":nil}}>.');
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"test":{"b":truf}}');
                end, 'Unexpected character in JSON near <t":{"b":truf}}>.');
            end);

          It('Should be raised when an unescaped control character is present', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"test":"'#7'"}');
                end, 'Unexpected character in JSON near <"test":"'#7'"}>.');
            end);
        end);

      Describe('jxStartBracket', procedure
        begin
          It('Should be raised when JSON string does not start with a left brace', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('this is not JSON');
                end, 'Expected left brace to start object near <this is not JSON>.');
            end);
        end);

      Describe('jxColonExpected', procedure
        begin
          It('Should be raised when JSON key value pair is not separated by a colon', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"boolean":True,"test" 1.234}');
                end, 'Expected colon separating key value near <,"test" 1.234}>.');
            end);
        end);

      Describe('jxCommaExpected', procedure
        begin
          It('Should be raised when JSON object members are not separated by a comma', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"boolean":True,"name":"bob" "test":1.234}');
                end, 'Expected comma separating object/array members near <":"bob" "test":1.>.');
            end);

          It('Should be raised when JSON array members are not separated by a comma', procedure
            begin
              ExpectException(procedure
                begin
                  TJSONObject.Create('{"boolean":True,"alphabet":["a","b","c" "d","e","f","g"]}');
                end, 'Expected comma separating object/array members near <"b","c" "d","e",">.');
            end);
        end);
    end);
end;

procedure RunMahoganyTests;
var
  LogToConsole: TMessageProc;
begin
  // log messages to the console
  LogToConsole := procedure(msg: String)
    begin
      WriteLn(msg);
    end;

  // run the tests and report failures
  RunTests(LogToConsole);
  WriteLn(' ');
  ReportResults(LogToConsole);
end;

begin
  try
    BuildMahoganyTests;
    RunMahoganyTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
