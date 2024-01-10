% SL_text_outputs.m
% code to write out text files with results after running SL calcluations
% Written by Chris Bassett and Alex De Robertis
% Last edits: 3 Jan, 2024


%% Now write out a text file with the CPA distances
% Create a text file and write out important results
textfn = [resultspath '\CPA_distances.txt']; 

% Write distances of CPAs
fid = fopen(textfn,'at');
fprintf(fid,'The ranges at CPA were:');
fprintf(fid,'\n');
fns = fields(DWT);
for i = 1:length(fns)
    cpaln = sprintf('     Pass %i - %0.f m',i,DWT.(fns{i}).CPA);
    fprintf(fid,cpaln);
    fprintf(fid,'\n');
end
fprintf(fid,'\n');
fclose('all')


%% Let's export the source level data in a way that they are easily understood and used elsewhere.
% compute ICES OTO
low_inds = find(SL.fTOL <= 1000); % indices for low-freq portion of curve
high_inds = find(SL.fTOL > 1000); % indices for high-freq portion of the curve
n1 = 135 - 1.66.*log10(SL.fTOL(low_inds));     % SPL for low-freq 
n2 = 130-22.*log10(SL.fTOL(high_inds)./1000);  % SPL for high-freq
ICES_OTO = [n1;n2];                         % make one curve for SPLs

result=table();
result.Frequency=SL.fTOL;
result.ICES_209_SL=ICES_OTO;
result.Bandwidth=SL.TOLbw;
result.TOL_SPL_RAW=SL.TOL_raw-10*log10(SL.TOLbw);
result.TOL_SPL_3dB_SNR=SL.TOL_SNR_3dB-10*log10(SL.TOLbw);
result.SL_relative_to_ICES=result.TOL_SPL_3dB_SNR-result.ICES_209_SL;
result.SNR_shallow=SL.SNRS;
result.SNR_middle=SL.SNRM;
result.SNR_deep=SL.SNRD;
result.num_hyds_used_SNR3dB=SL.num_hyds_SNR3dB;
result.index_all_hyds_SNR6dB=SL.index_all_hyds_SNR6dB;
result.SPL_pass1=SL.TOL_by_pass_SNR3dB(:,1)-10*log10(result.Bandwidth);
result.SPL_pass2=SL.TOL_by_pass_SNR3dB(:,2)-10*log10(result.Bandwidth);
result.SPL_pass3=SL.TOL_by_pass_SNR3dB(:,3)-10*log10(result.Bandwidth);
result.SPL_pass4=SL.TOL_by_pass_SNR3dB(:,4)-10*log10(result.Bandwidth);
result.SPL_pass5=SL.TOL_by_pass_SNR3dB(:,5)-10*log10(result.Bandwidth);
result.SPL_pass6=SL.TOL_by_pass_SNR3dB(:,6)-10*log10(result.Bandwidth);

% write out the table
writetable(result,[resultspath '\radiated_noise_results.csv']) % write out the table

clear n1 n2 low_inds high_inds ICES_OTO % clean up

%% Write to command line to tell user it is the code is done
disp('The code finished running.')
disp('Check the Results directory for summary text tables')