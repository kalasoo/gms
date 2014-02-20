module type ELEMENT = sig
  
  include Set.OrderedType

  val to_string : t -> string

end

module ElementSet (Ele : ELEMENT) = struct
  
  include Set.Make(Ele)

  let print_elements elements =
    let fold_element element s = Ele.to_string element ^ " " ^ s in
    fold fold_element elements ""

  let init_from_list l =
    List.fold_left (fun s ele -> add ele s) empty l

end

module MartelliSemiring (Ele : ELEMENT) = struct

  module S = ElementSet(Ele)

  include Set.Make(S)

  let reduce a = 
    let not_subset set = for_all (fun a_set -> not (S.subset a_set set) || S.equal a_set set) a in
    filter not_subset a

  let plus a b = 
    let fold_element a_set s = fold (fun b_set s_iter -> add (S.union a_set b_set) s_iter) b s in
    fold fold_element a empty

  let plus_reduce a b = 
    reduce (plus a b)

  let times a b =
    union a b

  let times a b =
    reduce (times a b)

  let zero = empty

  let one = 
    let s = empty in
    add S.empty s

  let length a =
    List.length ( elements a )

  let print_elements a = 
    print_endline "{";
    iter (fun i -> print_endline ("\t{ " ^ (S.print_elements i) ^ "}")) a;
    print_endline "}"

  let init_from_list l = 
    List.fold_left (fun ss inner_l -> add (S.init_from_list inner_l) ss) empty l

end

module MatrixMartelliSemiring (Ele : ELEMENT) = struct
    
  module MS = MartelliSemiring(Ele)

  let init_from_list n l =
    if float_of_int (List.length l) = (float_of_int n) ** 2. then
      let m = Array.make_matrix n n MS.zero in
      for i = 0 to n - 1 do
        for j = 0 to n - 1 do
          m.(i).(j) <- List.nth l (i * n + j)
        done;
      done;
      m
    else
      raise (Failure "Invalid dimension and list ")

  let plus n a b = 
    let m = Array.make_matrix n n MS.zero in
    for i = 0 to n - 1 do
      for j = 0 to n - 1 do
        m.(i).(j) <- MS.plus a.(i).(j) b.(i).(j)
      done;
    done;
    m

  let inner_times n a_row b_col =
    let result = ref (MS.zero) in
    Array.iteri (fun i a_i -> result := MS.plus !result (MS.times a_i b_col.(i)) ) a_row;
    !result

  (* get jth column of m *)
  let column n j m =
    if j < n then 
      let col = Array.make n MS.zero in
      for i = 0 to n - 1 do 
        col.(i) <- m.(i).(j)
      done;
      col
    else 
      raise (Failure "Column out of bounds.")

  let times n a b =
    let m = Array.make_matrix n n MS.zero in
    for i = 0 to n - 1 do
      let a_row = a.(i) in
      for j = 0 to n - 1 do
        let b_col = column n j b in
        m.(i).(j) <- inner_times n a_row b_col
      done;
    done;
    m

  let zero n =
    Array.make_matrix n n MS.zero

  let one n = 
    let m = Array.make_matrix n n MS.zero in
    for i = 0 to n - 1 do
      for j = 0 to n - 1 do
        if i = j then m.(i).(j) <- MS.one
      done;
    done;
    m

end

module MString = struct
  include String
  let to_string s = s
end

module MInt = struct
  include Int32
  let to_string i = string_of_int i
end

module MS = MartelliSemiring(MString)

let l1 = ["a"]
let l2 = ["b"; "c";]
let l3 = ["d"; "e"; "f"]
let l4 = ["a"; "b"]

let s1 = MS.init_from_list [l1;l2]
let s2 = MS.init_from_list [l1;l2;l3]
let s3 = MS.init_from_list [l1;l4]

  