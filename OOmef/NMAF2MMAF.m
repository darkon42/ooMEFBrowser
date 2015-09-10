function maf = NMAF2MMAF(maf, filepath, filename)
%NMAF2MMAF Read MAF using .NET class and convert to the Matlab class
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% CC Jouny - Johns Hopkins University - 2014 (c) 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p=mfilename('fullpath');
k=strfind(p,filesep);
localpath=p(1:k(end));
NET.addAssembly(fullfile(localpath, 'MEF.dll')); % From G:\Dropbox\work\sources\Visual Studio 2013\Projects\MEF_CSHARP\MEF\bin\Release\MEF.dll

mafNETfile=MEF.MAFFile(fullfile(filepath, filename));   % .NET class version
mafNETfile.readMAF();                                   % Read MAF file

% Now convert it to Matlab class
maf.PYID=char(mafNETfile.subject.Subject_nbr);
maf.nb_episodes=mafNETfile.timeline.nperiod;
maf.stream_label_list={};
maf.mef_streams=MEF_stream.empty(maf.MAX_STREAM,0);

IDcounter=0;
for nepisode=1:maf.nb_episodes,                                                 % Loop over episode
    current_episode=mafNETfile.subject.episodes.Item(nepisode-1);               % zero indexing
    maf.start_times(nepisode)=current_episode.RST;
    maf.end_times(nepisode)=current_episode.RET;
    if nepisode>1,
        if current_episode.RST<mafNETfile.subject.episodes.Item(nepisode-2).RET,
            fprintf('Timestamps inconsistency at start of episode %d @ %s\n', nepisode, usec2date(current_episode.RST));
        end
    end
    
    for nsource=1:current_episode.nbsources,                                            % Loop of sources
        current_label=char(current_episode.sources.Item(nsource-1).label);
        label_exist=strcmp(maf.stream_label_list, current_label);
        if ~any(label_exist),                                                       % Check if stream already exist for this label
            IDcounter=IDcounter+1;                                                  % if not add a stream & increase counter
            maf.mef_streams(IDcounter)=MEF_stream();                                % Add new stream if not
            maf.mef_streams(IDcounter).Init_Stream(current_label);                  % Initialize the stream
            maf.stream_label_list{IDcounter}=current_label;                         % Add label to the stream list
            maf.mef_streams(IDcounter).ID=IDcounter;                                % Set stream ID
            maf.mef_streams(IDcounter).mef_files=MEF_file.empty(maf.MAX_EPISODE, 0);% Create empty mef files sources array
            sourceID=IDcounter;
        else
            idx=find(label_exist);                                                  % If stream already exist
            if length(idx)>1,
                disp('Duplicate Label. Cannot continue indexing MAF');              % More than 1 stream with same label - should never happen
                return;
            else
                sourceID=idx;                                                       % Add to this stream
            end
        end
        
        try
            maf.mef_streams(sourceID).mef_files(nepisode)=MEF_file();               % Init new MEF File
        catch
            disp('oops'); % Not sure what was that
        end
        maf.mef_streams(sourceID).mef_files(nepisode).filepath=filepath;
        
        current_file=char(current_episode.sources.Item(nsource-1).filename);
        maf.mef_streams(sourceID).mef_files(nepisode).filename=current_file;
        maf.mef_streams(sourceID).mef_files(nepisode).label=current_label;           % Add Label
        % No check for file exist - not our concern here
        maf.mef_streams(sourceID).start_times(nepisode)=current_episode.RST;         % Copy start and end times
        maf.mef_streams(sourceID).end_times(nepisode)=current_episode.RET;
    end
end
maf.nb_stream=IDcounter;


