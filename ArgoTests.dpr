program ArgoTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  maMain in 'lib\Mahogany\maMain.pas',
  Argo in 'Argo.pas';

procedure BuildMahoganyTests;
var
  obj: TJSONObject;
  ary: TJSONArray;
  json: String;
  h: Integer;
begin
  Describe('JSONArray', procedure
    begin
      It('Constructor should work', procedure
        begin
          ary := TJSONArray.Create;
        end, true);

      Describe('String values', procedure
        begin
          It('Out of bounds indices should return an empty string', procedure
            begin
              ExpectEqual(ary.S[0], '', '');
            end);

          It('Should be able to add string values', procedure
            begin
              ary.Add('Testing');
            end);

          It('Should be able to retrieve string values', procedure
            begin
              ExpectEqual(ary.S[0], 'Testing');
            end);

          It('Should be able to replace string values', procedure
            begin
              ary.S[0] := 'abc';
              ExpectEqual(ary.S[0], 'abc');
            end);
        end);

      Describe('Integer values', procedure
        begin
          It('Out of bounds indices should return 0', procedure
            begin
              ExpectEqual(ary.I[1], 0);
            end);

          It('Should be able to add integer values', procedure
            begin
              ary.Add(5647382910);
            end);

          It('Should be able to retrieve integer values', procedure
            begin
              ExpectEqual(ary.I[1], 5647382910);
            end);

          It('Should be able to replace integer values', procedure
            begin
              ary.I[1] := -1029384756;
              ExpectEqual(ary.I[1], -1029384756);
            end);
        end);

      Describe('Double values', procedure
        begin
          It('Out of bounds indices should return 0.0', procedure
            begin
              ExpectEqual(ary.D[2], 0.0);
            end);

          It('Should be able to add double values', procedure
            begin
              ary.Add(1.414213562);
            end);

          It('Should be able to retrieve double values', procedure
            begin
              ExpectEqual(ary.D[2], 1.414213562);
            end);

          It('Should be able to replace double values', procedure
            begin
              ary.D[2] := -2.71828182845;
              ExpectEqual(ary.D[2], -2.71828182845);
            end);
        end);

      Describe('Array values', procedure
        begin
          It('Out of bounds indices should return nil', procedure
            begin
              Expect(not Assigned(ary.A[3]));
            end);

          It('Should be able to add array values', procedure
            begin
              ary.Add(TJSONArray.Create);
            end);

          It('Should be able to retrieve array values', procedure
            begin
              h := ary.A[3].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace array values', procedure
            begin
              ary.A[3] := TJSONArray.Create;
              Expect(ary.A[3].GetHashCode <> h);
            end);
        end);

      Describe('Object values', procedure
        begin
          It('Out of bounds indices should return nil', procedure
            begin
              Expect(not Assigned(ary.O[4]));
            end);

          It('Should be able to add object values', procedure
            begin
              ary.Add(TJSONObject.Create);
            end);

          It('Should be able to retrieve object values', procedure
            begin
              h := ary.O[4].GetHashCode;
              Expect(h > 0);
            end);

          It('Should be able to replace object values', procedure
            begin
              ary.O[4] := TJSONObject.Create;
              Expect(ary.O[4].GetHashCode <> h);
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

          It('Should preserve field order from assignment', procedure
            begin
              Expect(Pos('"string":', json) < Pos('"boolean":', json), 'Should serialize string before boolean');
              Expect(Pos('"boolean":', json) < Pos('"integer":', json), 'Should serialize boolean before integer');
              Expect(Pos('"integer":', json) < Pos('"double":', json), 'Should serialize integer before double');
              Expect(Pos('"double":', json) < Pos('"array":', json), 'Should serialize double before array');
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
