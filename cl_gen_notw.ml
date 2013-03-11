open Util
open Genutil
open C

let generate n =
   let sign = !Genutil.sign in
   let ename = expand_name !Magic.codelet_name in

   let make_acc () = locative_array_c n
      (Printf.sprintf "v%d->s0")
      (Printf.sprintf "v%d->s1")
      (unique_array_c n) "" in
   let input = load_array_c n (make_acc ()) in
   let output = store_array_c n (make_acc ()) in

   let dag = output (Fft.dft sign n input) in
   let annot = standard_optimizer dag in

   let tree = Fcn ("void", ename,
      (List.map (fun i -> Decl ("real2_t *", Printf.sprintf "v%d" i)) (iota n)),
      finalize_fcn (Asch annot))
   in ((unparse tree) ^ "\n")

let main () =
   begin
      let usage = "Usage: " ^ Sys.argv.(0) ^ " -n <number>" in
         parse [] usage;
      print_string "#define E real_t\n";
      print_string "#define DK(name, value) const E name = value\n";
      print_string "#define FMA(a, b, c) fma(a, b, c)\n";
      print_string "#define FMS(a, b, c) fma(a, b, -(c))\n";
      print_string "#define FNMA(a, b, c) (-fma(a, b, c))\n";
      print_string "#define FNMS(a, b, c) fma(-a, b, c)\n";
      print_string (generate (check_size ()));
   end

let _ = main()
