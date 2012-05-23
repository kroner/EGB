listFromMHT = h -> (
     l := new MutableList;
     i := 0;
     while h#? i do (
	  l#i = h#i;
	  i = i+1;
	  );
     return new List from l;
     )

divWitness = (v,w) -> (
     v = (listForm v)#0#0;
     w = (listForm w)#0#0;
     n := length v;
     sigma := new MutableHashTable;
     i := n-1;
     for j in reverse(0..n-1) do (
	  while v#i == 0 and i >= 0 do i = i-1;
	  if j > i then continue;
	  if v#i <= w#j then (
	       sigma#j = i;
	       i = i-1;
	       )
	  );
     if #sigma != #select(v,a -> a != 0) then return (false, {});
     i = n-1;
     for j in reverse(0..n-1) do (
	  if not sigma#? j then (
	       while v#i != 0 and i >= 0 do i = i-1;
	       sigma#j = i;
	       i = i-1;
	       );
	  );
     sigma = listFromMHT(sigma);
     assert(length sigma == n);
     return (true, sigma);
     )

gDivWitness = (v,w) -> (
     v = (listForm v)#0#0;
     w = (listForm w)#0#0;
     n := length v;
     sigma := new MutableHashTable;
     i := n-1;
     for j in reverse(0..n-1) do
	  if v#i <= w#j then (
	       sigma#j = i; 
	       i = i-1;
	       );
     for j in reverse(0..n-1) do
	  if not sigma#? j then (
	       if v#i != 0 then return (false, {});
	       sigma#j = i;
	       i = i-1;
	       );
     sigma = listFromMHT(sigma);
     assert(length sigma == n);
     return (true, sigma);
     )

permute = (b,sigma) -> (
     X := gens ring b;
     s := apply(length X, i -> (X#(sigma#i) => X#i));
     return sub(b,s);
     )

spoly = (f,g) -> (
     l = lcm(leadMonomial f,leadMonomial g);
     return (l//(leadTerm f))*f - (l//(leadTerm g))*g;
     )

nextPerm = P -> (
     n := #P;
     i := 1;
     while i < n and P#(i-1) > P#i do i = i+1;
     if i == n then return new MutableList;
     Q := sort new List from take(P,i);
     apply(i, k -> (P#k = Q#k));
     j := 1;
     while j < i and P#j < P#i do j = j+1;
     a := P#i;
     P#i = P#(j-1);
     P#(j-1) = a;
     return P;
     )

allPerms = n -> (
     Perms := new MutableList;
     p := new MutableList from (0..n-1);
     while #p != 0 do (
	  Perms#(#Perms) = new List from p;
	  p = nextPerm(p);
	  );
     return new List from Perms;
     )

reduce = method(Options=>{Completely=>false})
reduce (RingElement, BasicList) := o -> (f,B) -> (
     B' := select(toList B,b->b!=0);
     R := ring f;
     r := 0;
     while f != 0 do (
	  divOccurred := false;
	  for b in B' do (
	       (isDiv, sigma) = gDivWitness(b,f);
	       --print (isDiv, sigma);
	       if isDiv then (
		    sb := permute(b,sigma);
		    f = spoly(f,sb);
		    divOccurred = true;
		    break;
		    );
	       );
	  if not divOccurred then (
	       r = r + leadTerm f;
	       f = f - leadTerm f;
	       );
	  );
     if not o.Completely or r == 0 then r
     else leadTerm r + reduce(r - leadTerm r, B', Completely=>true) 
     )

reduceGB = G -> (
     G = select(G, g -> (
	       keep := true;
	       for f in G do (
		    if f != g and (divWitness(f,g))#0 then keep = false;
		    );
      	       if not keep then <<"r"<<flush;
	       return keep;
	       )
	  );
     return apply(G, g -> (g//leadCoefficient g));
     )
			 

truncatedGB = F -> (
     R := ring F#0;
     n := numgens R;
     Perms := allPerms(n);
     i := 0;
     while i < #F do (
	  for j from 0 to i do (
	       --s := new MutableList from (0..n-1);
	       --while #s != 0 do (
	       for s in Perms do (
		    --t := new MutableList from (0..n-1);
		    --while #t != 0 do (
		    for t in Perms do (
			 f := spoly(permute(F#i,s), permute(F#j,t));
			 r := reduce(f,F);
			 --if f != 0 then print (permute(F#i,s), permute(F#j,t),f,r);
			 if r != 0 then (<<"n"<<flush; F = --interreduceGB 
			      append(F,r));
			 --t = nextPerm(t);
			 );
		    --s = nextPerm(s);
		    );
	       );
	  i = i+1;
	  );
     return reduceGB F;
     )

processSpairs = method(Options=>{Symmetrize=>true})
processSpairs (List,ZZ) := o -> (F,k) -> (
     R := ring F#0;
     n := numgens R;
     x := symbol x;
     R' := (coefficientRing R)[reverse(x_0..x_(n+k-1)), MonomialOrder => Lex];
     RtoR' := map(R',R, drop(gens R',1));
     F = F/RtoR';
     sp := shiftPairs(R',k);
     print sp;
     i := 0;
     nF := #F;
     scan(nF, i->
	  scan(nF, j->(
		    -- if i!=j then
		    for st in sp do (
		    	 (s,t) := st;
		    	 f := spoly(s F#i, t F#j);
		    	 r := reduce(f,F);
		    	 --if f != 0 then print (i,j,s,t);
		    	 if r != 0 then (
			      print "(n)"; 
			      if i==j then print(F#i,F#j,r,matrix s,matrix t);
			      F = append(F,r)
			      );
		    	 );
	       	    ))
	  );
     if o.Symmetrize then interreduce symmetrize F else interreduce F
     )

shiftPairs = (R,k) -> (
     assert(k==1); -- assume k=1
     n := numgens R;
     apply(n, i->(map (R,R),
	       map(R,R,{0}|apply(toList(0..i-1) | toList (i+1..n-1), j->R_j))))
     )

symmetrize = method()
symmetrize List := F -> flatten (F/symmetrize)
symmetrize RingElement := f -> (
     R := ring f;
     supp'f := support f;
     apply(permutations supp'f, p->
	  (map(R,R,apply(#supp'f,i->supp'f#i=>p#i))) f
	  )
     )

interreduce = F -> (
     M := new MutableList from F;
     m := #F;
     local i;
     while( 
	   (i = position(0..m-1,i'-> 
		     any(m, j->j=!=i' and M#j != 0 and M#i'!= 0 and first gDivWitness(M#j,M#i'))
		     )     
	   ) =!= null  
     	  ) do (
	       M#i = reduce(M#i,drop(M,{i,i}))
	  );
     M = toList select(M, f->f!=0);
     apply(M, f->makeMonic(leadTerm f + reduce(f-leadTerm f,M,Completely=>true)))
     ) 

makeMonic = f -> f/leadCoefficient f 
