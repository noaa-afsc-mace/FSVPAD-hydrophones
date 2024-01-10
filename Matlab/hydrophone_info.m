function [outstr1, outstr2] = hydrophone_info(fname)
% creates output strings based on filenames and paths
% fname should be the first file name from the total list 
% of filenames

if ~isempty(strfind( fname,'Deep'))
outstr1 = 'Deep';
elseif ~isempty(strfind( fname,'Mid'))
outstr1 = 'Midwater';
else ~isempty(strfind( fname,'Shallow'))
outstr1 = 'Shallow';
end

[fp,fname,fext] = fileparts(fname);
outstr2 = ['H' fp(1,end-5:end)];

end

