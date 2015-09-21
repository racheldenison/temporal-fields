function rd_combineRunsTemporalAttention(subject)

%% setup
if nargin==0
    % subject = 'ecPilot_cb_tilt1pt5_tc64-100_soa1000-1250';
    subject = 'ax_cbD10_tilt2pt3_tc16-64_soa1000-1800';
end
runs = 1:3;
combinedRun = 8;
nRuns = numel(runs);

saveData = 1;
saveFigs = 1;

excludeFirstBlock = 0;
nGoodTrialsToExclude = 64;
startingExcludeTrials = [1 193];

expName = 'E4_contrast_cbD10'; % 'E2_SOA_cbD6', 'E0_cb'
% dataDir = 'data';
% figDir = 'figures';
dataDir = pathToExpt('data');
figDir = pathToExpt('figures');
dataDir = sprintf('%s/%s/%s', dataDir, expName, subject(1:2));
figDir = sprintf('%s/%s/%s', figDir, expName, subject(1:2));

if excludeFirstBlock
    fprintf('\n\nExcluding first good block of each session!\n\n')
end

%% initializations
subjectID = sprintf('%s_run%02d', subject, combinedRun);
trials = [];
targetRotations = [];
trialOrder = [];

%% get data from each run
for iRun = 1:nRuns
    run = runs(iRun);
    dataFile = dir(sprintf('%s/%s_run%02d*TemporalAttention*', dataDir, subject, run));
    data = load(sprintf('%s/%s', dataDir, dataFile.name));
    
    if excludeFirstBlock && (run==1 || run==2)
        excludedTrials = rd_temporalAttentionExcludeTrials(data.expt, ...
            startingExcludeTrials(run), nGoodTrialsToExclude);
        data.expt.trials(excludedTrials,8:end) = NaN;
    end
    
    trials = [trials; data.expt.trials];
    targetRotations = [targetRotations; data.expt.targetRotations];
    trialOrder = [trialOrder; data.expt.trialOrder + size(trialOrder,2)];
    
    timing(iRun) = data.expt.timing;
end

%% make the combined expt
expt.subjectID = subjectID;
expt.runs = runs;
expt.p = data.expt.p; % assume all runs identical
expt.timing = timing;
expt.trialOrder = trialOrder;
expt.trials_headers = data.expt.trials_headers; % assume all runs identical
expt.trials = trials;
expt.targetRotations = targetRotations;

%% analyze data
[expt results] = rd_analyzeTemporalAttention(expt);

%% save data
% saving data and figs separately in order to save them into the mcq
% directory, and not locally
if saveData
    fileName = sprintf('%s/%s_TemporalAttention_T1T2all_%s.mat', dataDir, subjectID, datestr(now, 'yyyymmdd'));
    save(fileName, 'expt', 'results')
end

%% save figs
if saveFigs
    figNames = {'acc','rt'};
    rd_saveAllFigs([], figNames, [subjectID '_TemporalAttention_T1T2all'], figDir)
end
    