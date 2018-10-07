clearvars
clc
tic
level = [6 6 6 6];
diff{1} = 'easy';
diff{2} = 'medium';
diff{3} = 'hard';
diff{4} = 'difficult';
n   = 7;
[monsterlist,threshold] = getCombinations(level,n,diff{2});
toc
function [monsterlist,partyThreshold] = getCombinations(level,num,diff)
%GETCOMBINATIONS Summary of this function goes here


    % Establish arrays of of CR, XP, and XP threshold, and Multiple
    % Monster multipliers
    CR = [0 .125 .25 .5 1:30];
    XP = [0 25 50 100 200 450 700 1100 1800 2300 2900 3900 5000 5900 7200 8400 ...
          10000 11500 13000 15000 18000 20000 22000 25000 33000 41000 50000 ...
          62000 75000 90000 105000 120000 135000 155000];

    baseThreshold = [   25 50 75 100
                        50 100 150 200 
                        75 150 225 400
                        125 250 375 500
                        250 500 750 1100
                        300 600 900 1400
                        350 750 1100 1700
                        450 900 1400 2100
                        550 1100 1600 2400
                        600 1200 1900 2800
                        800 1600 2400 3600
                        1000 2000 3000 4500
                        1100 2200 3400 5100
                        1250 2500 3800 5700
                        1400 2800 4300 6400
                        1600 3200 4800 7200
                        2000 3900 5900 8800
                        2100 4200 6300 500
                        2400 4900 7300 10900
                        2800 5700 8500 12700];
    MMMult = [1 1.5 2 2 2 2 2.5 2.5 2.5 2.5 3 3 3 3 4];
    
    partyThreshold = [0 0 0 0];
    % calculate party XP threshold
    for i = 1:length(level)
        partyThreshold = partyThreshold+baseThreshold(level(i),:);
    end
    
    % adjust for small or large parties as necessary
    if length(level) < 3
        uniquemult = unique(MMMult);
        [~,loc] = ismember(MMMult(num),uniquemult);
        if loc+1>length(uniquemult)
            adjMMMult = MMMult(num);
        else
            adjMMMult = MMMult(loc+1);
        end
    elseif length(level) > 6
        [~,loc] = ismember(MMMult(num),uniquemult);
        if loc-1<1
            adjMMMult = MMMult(num);
        else
            adjMMMult = MMMult(loc-1);
        end
    else
       adjMMMult = MMMult(num);
    end
    
    partyThreshold = partyThreshold/adjMMMult;

    %set encounter threshold for selected difficulty
    switch diff
        case 'easy'
            min = partyThreshold(1);
            max = partyThreshold(2);
        case 'medium'
            min = partyThreshold(2);
            max = partyThreshold(3);
        case 'hard'
            min = partyThreshold(3);
            max = partyThreshold(4);
        case 'deadly'
            min = partyThreshold(4);
            max = partyThreshold(4)+partyThreshold(2);
    end
    
    %enter recursive algorith to build list of possible combinations
    meanLevel = mean(level);
    if meanLevel>=16
        minCRidx = find(CR==2);
    elseif meanLevel>=11
        minCRidx = find(CR==1);
    else
        minCRidx = find(CR==0.125);
    end
    
    [monsterlist, ~] = getNextMonster(ones(9999999,num+1),ones(1,num),1,1,CR,XP,min,max,minCRidx);
    lastrow = find(monsterlist(:,end)==1,1,'first')-1;
    if lastrow == 0
        monsterlist = [];
    else
        monsterlist = monsterlist(1:lastrow,:);
        monsterlist(:,end) = monsterlist(:,end)*adjMMMult;
    end
    partyThreshold = partyThreshold*adjMMMult;

end

function [monsterlist,row] = getNextMonster(monsterlist,curCRidx,row,col,CR,XP,min,max,minCRidx)
%for each monster CR
    if col==1
        CRstart = length(CR);
    else
        CRstart = curCRidx(col-1);
    end
    
    for i = CRstart:-1:minCRidx %we go to two since the first CR is zero with zero XP
        if sum(XP(curCRidx)) + XP(i) > max
            % if the sum of the XP of the current monsters plus the current
            % monster exceed the threshold, continue to the next lower CR
            continue
        elseif sum(XP(curCRidx)) + XP(i)*(length(curCRidx)-col+1) < min
            % if the sum of the XP of the current monsters plus the
            % number of remaining monsters all of the current CR do not
            % reach the minimum threshold, exit the current level of
            % recursion
            break
        elseif col==length(curCRidx)
            %if this is the last monster and the two previous
            %conditions were not met, then this is a viable monster
            curCRidx(col) = i;
            monsterlist(row,:) = [CR(curCRidx) sum(XP(curCRidx))];
            row = row+1;
        else
            %proceed to the next level of recursion
            newCRidx = curCRidx;
            newCRidx(col) = i;
            [monsterlist,row] = getNextMonster(monsterlist,newCRidx,row,col+1,CR,XP,min,max,minCRidx);
        end
    end
    
end

