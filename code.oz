% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd' 'mettre son propre chemin pour le fichier :)'}

   % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
   % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
   %
   % Projet fournit quatre fonctions :
   % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
   % {Projet.readFile FileName} = AudioVector OR error(...)
   % {Projet.writeFile FileName AudioVector} = ok OR error(...)
   % {Projet.load 'music_file.dj.oz'} = La valeur oz contenue dans le fichier chargé (normalement une <musique>).
   %
   % et une constante :
   % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}

   local
      Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
      
      % Flatten réduit les listes de listes de ... en liste simple
      fun{Flatten L}
        case L
	of nil then nil
	[] H|T then {Append {Flatten H} {Flatten T}}
	else [L]
        end
      end
      
      fun{ComputeDemiTons Note}
      	local Diff Alt
        in
          case Note.nom of a then Diff=0
          [] b then Diff=2
          [] c then Diff=~9
          [] d then Diff=~7
          [] e then Diff=~5
          [] f then Diff=~4
          [] g then Diff=~2
          end
	  if Note.alteration=='#' then Alt=1
	  else Alt=0
	  end
          (Note.octave-4)*12+Diff+Alt
        end
      end
      	
      
      fun {ToNote Note}
         case Note
	 of Nom#Octave then note (nom:Nom octave:Octave alteration :'#')
	 [] Atom then
	    case {AtomToString Atom}
	    of [N] then note (nom : Atom octave : 4 alteration : none)
	    [] [N O] then note (nom:{StringToAtom [N]}
	    			octave:{StringToInt [O]}
	    			alteration:none)
	    else silence
	    end
	 end
       end
      
      fun{NoteToEchantillon Note}
      	case Note
      	of silence then silence(duree:1.0)
      	[] note(nom:X octave:Y alteration:Z) then echantillon(hauteur:{ComputeDemiTons Note} duree:1.0 instrument:none)
        end
      end
      
      fun{Bourdon X Y}
        case Y of nil then nil
	[]H|T then 
	     case X of silence then silence(duree:H.duree)|{Bourdon X T}
	     [] note(nom:N octave:Octave alteration:A) then echantillon(hauteur:{ComputeDemiTons X} duree:H.duree instrument:H.instrument)|{Bourdon X T}
	     end
	end
      end
      
      fun{Muet X}
        {Bourdon silence X}
      end
      
      fun{Etirer X Y}
      	case Y of nil then nil
      	[]H|T then
            case H of silence(duree:D) then silence(duree:D*X)|{Etirer X T}
            []echantillon(hauteur:Z duree:Y instrument:I) then echantillon(hauteur:Z duree:Y*X instrument:I)|{Etirer X T}
            end
        end
      end
      
      fun{DureePart X Acc}
	case X of nil then Acc
	[]H|T then {DureePart T Acc+H.duree}
	end
      end
      
      fun{Duree X Y}
      	case Y of nil then nil
      	[]H|T then {Etirer X/{DureePart Y 0.0} Y}
      	end
      end
      
      fun{Transpose X Y}
      	case Y of nil then nil
      	[]H|T then
      	    case H of silence(duree:D) then silence(duree:D)|{Transpose X T}
      	    []echantillon(hauteur:H duree:Y instrument:I) then echantillon(hauteur:H+X duree:Y instrument:I)|{Transpose X T}
            end
        end
      end

      fun{ToVector X} % Transforme un echatillon en vecteur
	local Comp Acc Aux Pi=3.141592 F=({Pow 2 X.hauteur/12.0}*440.0) in
	  fun{Aux X Acc Comp}
	    if Comp==(44100.0*X.duree) then Acc
	    else
	      {Aux X Acc|(0.5*{Sin ((2.0*Pi*F*Comp)/44100.0)}) Comp+1}
	    end
	  end
	{Aux X nil 0}
	end
      end

      fun{ListEchantillonToVector L} % transforme une liste d'echantillon en vecteur audio
	case L
	of H|T then
	  {Flatten {ToVector H}|{ListEchantillonToVector T}}
	end
      end

      fun{MergeToVector X}
	case X
	of H|T then
	  case H
	  of N#M then {Flatten {Ponderate N {Mix Interprete M}}|}
	end
      end

      fun{Ponderate N M} % pondere un vecteur audio avec N
	case M
	of H|T then
	  N*H|{Ponderate N T}
	end
      end

      fun{Dispatcher X} % fonction qui choisit le filtre adapte
	 case X
	 of renverser(M) then
	 [] repetition (nombre:N M) then
	 [] repetition(duree:S M) then
	 [] clip(bas:F1 haut:F2 M) then
	 [] echo(delai:S M) then
	 [] echo(delai:S decadence:F M) then
	 [] echo(delai:S decadence:F repetition:N M) then
	 [] fondu(ouverture:S1 fermeture:S2 M) then
	 [] fondu_enchaine(duree:S M1 M2) then
	 [] couper(debut:S1 fin:S2 M) then
	 end
      end
   
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
	 case Music
	 of nil then nil
	 []H|T then
	    case H
	    of voix(X) then {Flatten {VoiceToVector X}|{Mix Interprete T}}
	    []partition(P) then {Flatten {VoiceToVector {Interprete P}}|{Mix Interprete T}}
	    []wave(S) then {Flatten {Projet.readFile S}|{Mix Intreprete T}}
	    []merge(L) then {Flatten {MergeToVector L}|{Mix Interprete T}}
	    else {Flatten {Dispatcher H}|{Mix Interprete T}}
         %Audio
	    end
	 end
      end

      % Interprete doit interpréter une partition
      fun {Interprete Partition}
	local P={Flatten Partition} in
      	  case P of nil then nil
      	  []H|T then
            case H of muet(X) then {Flatten {Muet {Interprete {Flatten X}}}|{Interprete T}}
            []duree(secondes:X Y) then {Flatten {Duree X {Interprete {Flatten Y}}}|{Interprete T}}
            []etirer(facteur:X Y) then {Flatten {Etirer X {Interprete {Flatten Y}}}|{Interprete T}}
            []bourdon(note:X Y) then {Flatten {Bourdon {ToNote X} {Interprete {Flatten Y}}}|{Interprete T}}
            []transpose(demitons:X Y) then {Flatten {Transpose X {Interprete {Flatten Y}}}|{Interprete T}}
            []A then {Flatten {NoteToEchantillon {ToNote A}}|{Interprete T}}
            end
	  end
        end
      end

   local 
      Music = {Projet.load CWD#'joie.dj.oz'}
   in
      % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
      % vous devez mixer une musique qui démontre les fonctionalités de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validité de votre implémentation.
      {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
   end
end
