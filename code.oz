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
      fun { ToNote Note }
         case Note
	 of Nom# Octave then note (nom :Nom octave : Octave alteration :'#')
	 [] Atom then
	    case { AtomToString Atom }
	    of [N] then note ( nom : Atom octave : 4 alteration : none )
	    [] [N O] then note (nom :{ StringToAtom [N]}
	    			octave :{ StringToInt [O]}
	    			alteration : none )
	    end
	 end
      end
      fun{NoteToEchantillon Note}
      	%ajouter la fonction
      end
      fun{ComputeDemiTons Note}
      	local DiffDemiTons
      	  Error1
      	  Error2
      	  DiffOctave = Note.octave - 4 % 4 est l'octave fondamentale
      	  NoteString = {AtomToString Note.nom}
      	  Ref = {AtomToString 'a'}
      	  DiffNote = 2*(NoteString - Ref)
      	in
      	  if NoteString>98 then Error1 = 1
      	  elseif NoteString>101 then Error2 = 2
      	  else Error1=0
      	  end
      	  if Note.alteration=='#' then Error2=1
      	  else Error2=0
      	  end
      	12*DiffOctave+DiffNote+Erroe1+Error2
      	end
      end
      % Flatten réduit les listes de listes de ... en liste simple
      fun{Flatten L}
        case L
	of nil then nil
	[] H|T then {Append {FlattenList H} {FlattenList T}}
	else [L]
        end
      end
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
         Audio
      end

      % Interprete doit interpréter une partition
      fun {Interprete Partition}
         case Partition
	 of H|nil then {NoteToEchantillon {ToNote H}}
	 [] H|T then {Interprete H}|{Interprete T} % Il manque le cas pour une partition seule
	 [] muet( X ) then 
	 [] duree( secondes:X Y ) then
	 [] etirer( facteur:X Y ) then
	 [] bourdon( note:X Y ) then
	 [] transpose( demitons:X Y ) then
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
