unit ArgoTypes;

interface

uses
  Classes;

type
  TFastStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

  PArgoTreeNode = ^TArgoTreeNode;
  TArgoTreeNode = record
    Name: string;
    Value: Integer;
    Right: PArgoTreeNode;
    Left: PArgoTreeNode;
  end;

  TArgoTree = class(TObject)
  private
    Root: PArgoTreeNode;
    procedure Balance;
    function GetSize(node: PArgoTreeNode): Integer;
    function GetDepth(node: PArgoTreeNode): Integer;
    procedure DecrementNodes(node: PArgoTreeNode; value: Integer);
    procedure MoveNode(node, parentNode: PArgoTreeNode); overload;
    procedure MoveNode(node, parentNode, newNode: PArgoTreeNode); overload;
    procedure DeleteNode(node, parentNode: PArgoTreeNode);
    function CreateNode(name: string): PArgoTreeNode;
    function GetNode(name: String): PArgoTreeNode;
    procedure GetNodeContext(name: String; var cur, parent: PArgoTreeNode; var diff: Integer);
    function GetValue(name: String): Integer;
  public
    Size: Integer;
    constructor Create;
    procedure Delete(name: String);
    procedure Add(name: String);
    property Values[index: string]: Integer read GetValue; default;
  end;

implementation

uses
  SysUtils, Math;

{ TFastStringList }
function TFastStringList.CompareStrings(const S1, S2: string): Integer;
begin
  Result := CompareStr(S1, S2);
end;

{ TBinaryTree }
constructor TArgoTree.Create;
begin
  Size := 0;
end;

procedure TArgoTree.DecrementNodes(node: PArgoTreeNode; value: Integer);
begin
  if Assigned(node.Right) then
    DecrementNodes(node.Right, value);
  if node.Value > value then begin
    Dec(node.Value);
    if Assigned(node.Left) then
      DecrementNodes(node.Left, value);
  end;
end;

procedure TArgoTree.MoveNode(node, parentNode: PArgoTreeNode);
var
  minNode, minParent: PArgoTreeNode;
begin
  // get minimum node from right tree
  minNode := node.Right;
  minParent := node;
  while Assigned(minNode.Left) do begin
    minParent := minNode;
    minNode := minNode.Left;
  end;
  // then assign its name and value to node and delete it
  node.Name := minNode.Name;
  node.Value := minNode.Value;
  DeleteNode(minNode, minParent);
end;

procedure TArgoTree.MoveNode(node, parentNode, newNode: PArgoTreeNode);
begin
  if not Assigned(parentNode) then
    Root := newNode
  else if parentNode.Left = node then
    parentNode.Left := newNode
  else
    parentNode.Right := newNode;
end;

procedure TArgoTree.DeleteNode(node, parentNode: PArgoTreeNode);
var
  HasRightChildren, HasLeftChildren: Boolean;
begin
  HasRightChildren := Assigned(node.Right);
  HasLeftChildren := Assigned(node.Left);
  if HasRightChildren then begin
    if HasLeftChildren then
      MoveNode(node, parentNode)
    else
      MoveNode(node, parentNode, node.Right);
  end
  else if HasLeftChildren then
    MoveNode(node, parentNode, node.Left)
  else
    MoveNode(node, parentNode, nil);
end;

procedure TArgoTree.Delete(name: string);
var
  currentNode, previousNode: PArgoTreeNode;
  diff: Integer;
begin
  currentNode := Root;
  GetNodeContext(name, currentNode, previousNode, diff);
  if Assigned(currentNode) then begin
    // decrement larger values
    DecrementNodes(Root, currentNode.Value);
    DeleteNode(currentNode, previousNode);
    Dec(Size);
  end;
end;

function TArgoTree.GetSize(node: PArgoTreeNode): Integer;
begin
  Result := 0;
  if not Assigned(node) then
    exit;
  Result := 1 + GetSize(node.Left) + GetSize(node.Right);
end;

function TArgoTree.GetDepth(node: PArgoTreeNode): Integer;
begin
  Result := 0;
  if not Assigned(node) then
    exit;
  Result := 1 + Max(GetDepth(node.Left), GetDepth(node.Right));
end;

procedure TArgoTree.Balance;
var
  leftSize, rightSize: Integer;
begin
  // exit if no tree to balance
  if not Assigned(Root) then
    exit;
  leftSize := GetSize(Root.Left);
  rightSize := GetSize(Root.Right);
  // TODO
end;

function TArgoTree.GetNode(name: string): PArgoTreeNode;
var
  currentNode: PArgoTreeNode;
  diff: Integer;
begin
  currentNode := Root;
  // recursing search tree for matching node
  while Assigned(currentNode) do begin
    diff := CompareStr(name, currentNode.Name);
    if diff > 0 then
      currentNode := currentNode.Right
    else if diff < 0 then
      currentNode := currentNode.Left
    else
      break;
  end;
  // return node
  Result := currentNode;
end;

function TArgoTree.CreateNode(name: string): PArgoTreeNode;
begin
  New(Result);
  Result.name := name;
  Result.value := Size;
  Result.right := nil;
  Result.left := nil;
  Inc(Size);
end;

function TArgoTree.GetValue(name: string): Integer;
begin
  Result := GetNode(name).Value;
end;

procedure TArgoTree.GetNodeContext(name: String; var cur, parent: PArgoTreeNode; var diff: Integer);
begin
  while Assigned(cur) do begin
    parent := cur;
    diff := CompareStr(name, cur.Name);
    if diff > 0 then
      cur := cur.Right
    else if diff < 0 then
      cur := cur.Left
    else
      break;
  end;
end;

procedure TArgoTree.Add(name: string);
var
  currentNode, previousNode: PArgoTreeNode;
  diff: Integer;
begin
  // assign to root
  if not Assigned(Root) then begin
    Root := CreateNode(name);
    exit;
  end;
  // create new node
  currentNode := Root;
  GetNodeContext(name, currentNode, previousNode, diff);
  if Assigned(currentNode) then 
    raise Exception.Create('TArgoTree: Key "' + name + '" already present.')
  else begin
    if diff > 0 then
      previousNode.Right := CreateNode(name)
    else
      previousNode.Left := CreateNode(name);
  end;
end;

end.
