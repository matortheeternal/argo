# argo
A JSON framework for Delphi.  Allows you to create, serialize, and deserialize JSON objects.

## Motivation
I built this because the JSON libraries available for older versions of Delphi were not suitable for my needs.  I also thought it would be a good learning opportunity.

The name is a reference to **J**a**son**'s ship from Greek Mythology, The Argo.

## Differences from other JSON Libraries

- Preserves order of key value pairs in objects.  Serialization order will correspond to the order in which keys were assigned.
- Helpful exceptions with context when JSON parsing fails.
- Easy to understand code which you can adapt to your own needs.  There's only three major classes: TJSONValue, TJSONArray, and TJSONObject.
- Straightforward and simple API.
- High performance - faster than [superobject](https://github.com/hgourvest/superobject) on all operations except deserialization, where it is approximately 20% slower.  See [argo-benchmarks](https://github.com/matortheeternal/argo-benchmarks) for more details.

## Example code

### Objects

#### Setting values

```pas
  obj := TJSONObject.Create;
  obj.S['string'] := 'test';
  obj.B['boolean'] := True;
  obj.I['integer'] := 123;
  obj.D['double'] := 3.14159;
  obj.O['objects'] := TJSONObject.Create;
  obj.O['objects'].S['are'] := 'easy';
  obj.A['arrays'] := TJSONArray.Create;
  obj.A['arrays'].Add('are too!');
```

#### Removing values

```pas
  obj.Delete('key'); // removes property 'key'
```

#### Iteration

```pas
  // loops through and prints an object's keys and values
  for i := 0 to Pred(obj.Count) do
    WriteLn(obj.Keys[i] + ': ' + obj.ValueFromIndex[i].ToString);
```

### Arrays

#### Adding values

```pas
  ary := TJSONArray.Create;
  ary.Add('def');
  ary.Add(False);
  ary.Add(654);
  ary.Add(-4.67);
  ary.Add(TJSONArray.Create);
  ary.Add(TJSONObject.Create);
```

#### Replacing values

```pas
  ary.S[0] := 'abc';
  ary.B[1] := True;
  ary.I[2] := -987;
  ary.D[3] := 1.6180339;
  ary.A[4] := TJSONArray.Create('["hello"]');
  ary.O[5] := TJSONObject.Create('{"world":0}');
```

#### Removing values

```pas
  ary.Delete(0); // removes item at index 0
```

#### Iteration

```pas
  // prints values in array
  for i := 0 to Pred(ary.Count) do
    WriteLn(IntToStr(i) + ': ' + ary.Values[i].ToString);
    
  // replaces all values in array with string value 'test'
  for i := 0 to Pred(ary.Count) do
    ary.Values[i].Put('test');
```

### Serialization

```pas
  // using the object we defined above:
  WriteLn(obj.ToString);
  // output: {"string":"test","boolean":True,"integer":123,"double":3.14159,"object":{"objects":"are easy"},"arrays":["are too!"]}
  
  // using the array we defined above:
  WriteLn(ary.ToString);
  // output: ["abc",True,-987,1.6180339,["hello"],{"world":0}]
```

### Deserialization

```pas
  obj := TJSONObject.Create('{"jason":["and","the","argonauts"],"seek":"the golden fleece"}');
  ary := TJSONArray.Create('[True,"2",3,4.0,{}]');
  val := TJSONValue.Create('"all wrapped up"');
```
