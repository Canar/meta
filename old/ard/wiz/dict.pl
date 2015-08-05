%ontology%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%alternative to base.pl
%Dict(Word,Object,Id,Instance)

/*defines core classes
class([Definitions]).*/
class(q,symbol,'A unit of data that cannot be simplified without compromising meaning.').
class(w,blank,'White space. One or many non-visual characters.').
%list,'May contain duplicates but not cycles. Fundamentally identical with an array of pointers in C.').
class(l,list,'A group of symbols with implicit order.'). 
%char,'Represented internally with UTF-8, canonically. Other codepages must be available for import, but the import process will convert.').
class(c,char,'One symbol of a specific subset of all symbols.'). 
class(s,string,'A list of characters.').
class(n,number,'A number. A value.').

/* defines class hierarchy
subclass(Parent,Child).*/
subclass(w,nli).

symbol_class(a,'An atom. A letter of the alphabet. A concept. Precisely one of something.').
symbol_class(l,'A list. One or more atoms treated as one.').
symbol_class(c,'A character. A UTF-8 code point.').%Other codepages are available but untested and should remain that way.
symbol_class(s,'A string. A list of characters. If it is ever not just a single character, it is a string.').
symbol_class(n,'A number. A value.').

string_class('|','A line of text, terminated in a newline string.').
string_class(nli,'A newline string; potentially multiple encodings.').

action_class(p,'Parse. Convert data between formats, including display.').
action_class(x,'Execute arbitrary source code.').

%list_of(C,S):-(S=[H|T],character(S,H),string(S,T));S=[].

byte(w,W):-member(W,[10,13,32|"\t"]).
char(A,B):-byte(A,B).
char(nli,C):-setof(A,(str(nli,B),chars_to_atom(A,B)),C).
chars(A,L):-(L=[H|T],char(A,H),chars(A,T));char(A,L).
str(w,S):-chars(w,S).

str(newline_legacy,A):-chars_to_atom([10,13],A).
str(newline_legacy,A):-chars_to_atom([13,10],A).
str(newline_unix,A):-chars_to_atom([10],A).
str(newline_mac,A):-chars_to_atom([13],A).
str(nli,A):-str(newline_legacy,A);str(newline_unix,A);str(newline_mac,A).

w(W):-byte(w,W).
w([H|T]):-w(H),w(T).

/*overarching reference database
dict(Word,Object,Id,Instance).*/

/*object instantiation. a(list,s):There exists a string labeled s.
a(Type,MatchPattern).*/
a(list,[_|_]).
a(functor,X):-a(list,Y),X=..Y.

/*% type conversion system
to(FromType,ToType,From,To,Options). %*/
to(functor,list,F,T,[]):-F=..T.
to(list,functor,F,T,[]):-T=..F.
to(list,functor,[Pred|Args],T,args_list):-T=..[Pred,[Args]].
to(_,_,_,_,O):-c(O,', ',Co),p(['Unknown options: ', Co]).

to(FromType,ToType,From,To):-to(FromType,ToType,From,To,[]).


