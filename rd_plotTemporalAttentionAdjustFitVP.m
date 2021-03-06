% rd_plotTemporalAttentionAdjustFitVP.m

% standard_model = StandardMixtureModel_SD;
% @(data,g,sd)((1-g).*vonmisespdf(data.errors(:),0,deg2k(sd))+(g).*1/360)

%% group i/o
subjectIDs = {'bl','rd','id','ec','ld','en','sj','ml','ca','jl','ew','jx'};
% subjectIDs = {'ew'};
run = 9;
nSubjects = numel(subjectIDs);

plotDistributions = 1;
saveFigs = 0;

groupFigTitle = [sprintf('%s ',subjectIDs{:}) sprintf('(N=%d), run %d', nSubjects, run)];

modelName = 'VPK';

%% get data and plot data and fits
for iSubject = 1:nSubjects
    %% indiv i/o
    subjectID = subjectIDs{iSubject};
    subject = sprintf('%s_a1_tc100_soa1000-1250', subjectID);

    expName = 'E3_adjust';
    % dataDir = 'data';
    % figDir = 'figures';
    dataDir = pathToExpt('data');
    figDir = pathToExpt('figures');
    dataDir = sprintf('%s/%s/%s', dataDir, expName, subject(1:2));
    figDir = sprintf('%s/%s/%s', figDir, expName, subject(1:2));
    
    %% load data
%     dataFile = dir(sprintf('%s/%s_run%02d*', dataDir, subject, run));
%     load(sprintf('%s/%s', dataDir, dataFile(1).name))
    dataFile = dir(sprintf('%s/%s_run%02d_%s.mat', dataDir, subject, run, modelName));
    load(sprintf('%s/%s', dataDir, dataFile.name))
    
    % setup
    df = 4;
    xEdges = -90:df:90;
    xgrid = xEdges(1:end-1) + df/2; % bin centers
    
    % get and plot data and model pdfs
    targetNames = {'T1','T2'};
    validityNames = {'valid','invalid','neutral'};
    for iEL = 1:2
        for iV = 1:3
            % get errors for this condition
            errors = err{iV,iEL}*90/pi;
            n = histc(errors, xEdges);
            n(end-1) = n(end-1) + n(end); % last element of n contains the count of values exaclty equal to xEdges(end), so just combine it with the previous bin
            n(end) = [];
            
            % get fit parameters for this condition
            p = fit(iV,iEL).params;
            switch modelName
                case {'VP', 'VPK'}
                    J1bar = p(1);
                    tau = p(3);
                    kappa_r = p(4);
                otherwise
                    error('modelName not recognized')
            end
            
            % store fit parameters
            paramsData.J1bar(iV,iEL,iSubject) = J1bar;
            paramsData.tau(iV,iEL,iSubject) = tau;
            paramsData.kappa_r(iV,iEL,iSubject) = kappa_r;
            
            % calculate an empirical distribution using the fitted
            % parameters
            data_fit = gen_fake_VPA_data(p,1e5,2);
            modelN = histc(data_fit.error_vec*90/pi, xEdges);
            modelN(end-1) = modelN(end-1) + modelN(end); % last element of n contains the count of values exaclty equal to xEdges(end), so just combine it with the previous bin
            modelN(end) = [];
            
            % generate data and model pdfs (and find residuals) using a common
            % x-axis
            pdfData = (n/sum(n*df))';
%             pdfModel = (1-g).*vonmisespdf(xgrid,mu,deg2k(sd))+(g).*1/180;
            pdfModel = (modelN/sum(modelN*df))';            
            resid = pdfData - pdfModel;
            
            % store residuals
            resids(iV,iEL,iSubject,:) = resid;
%             residsShift(iV,iEL,iSubject,:) = circshift(resid,[0 round(mu/df)]);
            
            % also generate smooth model pdf for plotting
            x = -90:90;
            y0 = histc(data_fit.error_vec*90/pi, x);
            y = (y0/sum(y0*diff(x(1:2))))'; 
%             y = (1-g).*vonmisespdf(x,mu,deg2k(sd))+(g).*1/180;
            
            if plotDistributions
                ylims = [-0.02 0.06];
                validityOrder = [1 3 2];
                figure(iSubject)
                subplot(3,2,(validityOrder(iV)-1)*2+iEL)
                hold on
                plot(xgrid,pdfData)
                plot(x,y,'r','LineWidth',1.5)
                %         plot(xgrid,pdfModel,'.r')
                plot(xgrid, resid, 'g')
                ylim(ylims)
                title(sprintf('%s %s', targetNames{iEL}, validityNames{iV}))
            end
        end
    end
    if plotDistributions
        rd_supertitle(sprintf('%s, run %d', subjectID, run));
        if saveFigs
            print(gcf, '-depsc2', ...
                sprintf('%s/%s_run%02d_TemporalAttentionAdjust_fit_%s', figDir, subject, run, modelName))
        end
    end
end

%% plot average residuals
validityOrder = [1 3 2];
ylims = [-0.02 0.02];
figNames{1} = 'residsByCond';
f(1) = figure;
for iV = 1:3
    for iEL = 1:2
        subplot(3,2,(validityOrder(iV)-1)*2+iEL)
        hold on
        plot([-100 100], [0 0], '-k');
        plot(xgrid, squeeze(resids(iV,iEL,:,:)), 'g')
        plot(xgrid, mean(squeeze(resids(iV,iEL,:,:))), 'k', 'LineWidth', 2)
        ylim(ylims)
        title(sprintf('%s %s', targetNames{iEL}, validityNames{iV}))
        if iV==3 && iEL==1
            ylabel('residuals (data-model)');
        end
    end
end
rd_supertitle(groupFigTitle);
rd_raiseAxis(gca);

% all conditions on same plot
residsMean = squeeze(mean(resids,3));
figNames{2} = 'residsAllConds';
f(2) = figure;
hold on
plot(xgrid,squeeze(residsMean(:,1,:))')
plot(xgrid,squeeze(residsMean(:,2,:))')
plot(xgrid,squeeze(mean(mean(residsMean,1),2))','k','LineWidth',2)
plot([-100 100], [0 0], '-k');
legend(validityNames)
ylabel('p(error) residual mean')
rd_supertitle(groupFigTitle);
rd_raiseAxis(gca);


%% param summary
fieldNames = fields(paramsData);
for iField = 1:numel(fieldNames)
    fieldName = fieldNames{iField};
    paramsMean.(fieldName) = mean(paramsData.(fieldName),3);
    paramsSte.(fieldName) = std(paramsData.(fieldName),0,3)./sqrt(nSubjects);
end

%% plot fit parameters
validityOrder = [1 3 2];
fieldNames = fields(paramsMean);

% indiv subjects
ylims = [];
ylims.absMu = [-1 8];
ylims.mu = [-8 8];
ylims.g = [0 0.3];
ylims.sd = [0 30];
ylims.B = [0 0.06];
for iField = 1:numel(fieldNames)
    fieldName = fieldNames{iField};
    figNames{end+1} = [fieldName 'Indiv'];
    f(end+1) = figure;
    for iEL = 1:2
        subplot(1,2,iEL)
        bar(squeeze(paramsData.(fieldName)(validityOrder,iEL,:))')
        set(gca,'XTickLabel',subjectIDs)
        colormap(flag(3))
        xlim([0 nSubjects+1])
%         ylim(ylims.(fieldName))
        if iEL==1
            ylabel(fieldName)
            legend(validityNames(validityOrder))
        end
        title(targetNames{iEL})
    end
    rd_supertitle(groupFigTitle);
    rd_raiseAxis(gca);
end

% group
ylims.absMu = [-1 4];
ylims.mu = [-4 4];
ylims.g = [0 0.16];
ylims.sd = [0 25];
ylims.B = [0 0.06];
for iField = 1:numel(fieldNames)
    fieldName = fieldNames{iField};
    figNames{end+1} = [fieldName 'Group'];
    f(end+1) = figure;
    for iEL = 1:2
        subplot(1,2,iEL)
        hold on
        b1 = bar(1:3, paramsMean.(fieldName)(validityOrder,iEL),'FaceColor',[.5 .5 .5]);
        p1 = errorbar(1:3, paramsMean.(fieldName)(validityOrder,iEL)', ...
            paramsSte.(fieldName)(validityOrder,iEL)','k','LineStyle','none');
%         ylim(ylims.(fieldName))
        ylabel(fieldName)
        set(gca,'XTick',1:3)
        set(gca,'XTickLabel', validityNames(validityOrder))
        title(targetNames{iEL})
    end
    rd_supertitle(groupFigTitle);
    rd_raiseAxis(gca);
end

%% save figures
if saveFigs
    turnallwhite
    groupFigPrefix = sprintf('gE3_N%d_run%02d_%sMAP', nSubjects, run, modelName);
    rd_saveAllFigs(f, figNames, groupFigPrefix, [], '-pdf'); %-depsc2, -dpng
end
    



