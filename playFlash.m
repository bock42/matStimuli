function playFlash(outFile,stimFreq,stimDur,blockDur)
%% Displays a black/white full-field flicker
%
%   Usage:
%   playFlash(outFile,stimFreq,stimDur,blockDur)
%
%   Inputs:
%   outFile     - full path to output file containing timing of events, etc
%   stimFreq    - stimulus flicker frequency    (default = 16   [hertz])
%   stimDur     - duration of entire stimulus   (default = 336  [seconds])
%   blockDur    - duration of stimulus blocks   (default = 12   [seconds])
%
%   Stimulus will flicker at 16Hz, occilating between flicker and and grey 
%   screen based on 'blockDur'
%
%   Written by Andrew S Bock Jul 2016

%% Set defaults
if ~exist('stimFreq','var')
    stimFreq = 16; % seconds
end
if ~exist('stimDur','var')
    stimDur = 336; % seconds
end
if ~exist('blockDur','var')
    blockDur = 12; % seconds
end
if ~exist('display','var')
    display.distance = 106.5; % distance from screen (cm) - (SC3T);  124.25 - (HUP6)
    display.width = 69.7347; % width of screen (cm) - (SC3T); 50.4 - (HUP6)
    display.skipChecks = 2;
    display.bkColor = [128 128 128];
    display.screenNum = max(Screen('Screens'));
end
%% Initial settings
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 2); % Skip sync tests
screens = Screen('Screens'); % get the number of screens
screenid = max(screens); % draw to the external screen
%% For Trigger
a = cd;
if a(1)=='/' % mac or linux
    a = PsychHID('Devices');
    for i = 1:length(a)
        d(i) = strcmp(a(i).usageName, 'Keyboard');
    end
    keybs = find(d);
else % windows
    keybs = [];
end
%% Define black and white
black = BlackIndex(screenid);
white = WhiteIndex(screenid);
grey = white/2;
%% Screen params
res = Screen('Resolution',max(Screen('screens')));
display.resolution = [res.width res.height];
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseRetinaResolution');
[winPtr, windowRect] = PsychImaging('OpenWindow', screenid, grey);
[mint,~,~] = Screen('GetFlipInterval',winPtr,200);
display.frameRate = 1/mint; % 1/monitor flip interval = framerate (Hz)
display.screenAngle = pix2angle( display, display.resolution );
%rect = Screen('Rect', winPtr );
[screenXpix, screenYpix] = Screen('WindowSize', winPtr);% Get the size of the on screen window
display.resolution = [screenXpix screenYpix];
[center(1), center(2)] = RectCenter(windowRect); % Get the center coordinate of the window
fix_dot = angle2pix(display,0.25); % For fixation cross (0.25 degree)
%% Make images
greyScreen = grey*ones(display.resolution);
blackScreen = black*ones(display.resolution);
whiteScreen = white*ones(display.resolution);
Texture(1) = Screen('MakeTexture', winPtr, blackScreen);
Texture(2) = Screen('MakeTexture', winPtr, whiteScreen);
Texture(3) = Screen('MakeTexture', winPtr, greyScreen);
%% Display Text, wait for Trigger
try
    commandwindow;
    Screen('FillRect',winPtr, grey);
    Screen('TextSize',winPtr,40);
    DrawFormattedText(winPtr, 'SCAN STARTING SOON, HOLD STILL!!!', ...
        'center',display.resolution(2)/3,[],[],[],[],[],0);
    Screen('DrawDots', winPtr, [0;0], fix_dot,black, center, 1);
    Screen('Flip',winPtr);
    wait4T(keybs);  %wait for 't' from scanner.
    %% Drawing Loop
    breakIt = 0;
    frameCt = 0;
    curTR = 1;
    startTime = GetSecs;  %read the clock
    curFrame = 0;
    stim.startTime = startTime;
    stim.TRtime(curTR) = GetSecs;
    disp(['T ' num2str(curTR) ' received - 0 seconds']);
    lastT = startTime;
    while GetSecs-startTime < stimDur && ~breakIt  %loop until 'esc' pressed or time runs out
        % update timers
        elapsedTime = GetSecs-startTime;
        % get 't' from scanner
        [keyIsDown, secs, keyCode, ~] = KbCheck(-3);
        if keyIsDown % If *any* key is down
            % If 't' is one of the keys being pressed
            if ismember(KbName('t'),find(keyCode))
                if (secs-lastT) > 0.25
                    curTR = curTR + 1;
                    stim.TRtime(curTR) = GetSecs;
                    disp(['T ' num2str(curTR) ' received - ' num2str(elapsedTime) ' seconds']);
                    lastT = secs;
                end
            end
        end
        % Flip between grey and flicker 
        thisblock = floor(elapsedTime/blockDur);
        if mod(thisblock,2)
            if (elapsedTime - curFrame) > (1/(stimFreq*2))
                frameCt = frameCt + 1;
                Screen( 'DrawTexture', winPtr, Texture( mod(frameCt,2) + 1 )); % current frame
                % Flip to the screen
                Screen('Flip', winPtr);
                curFrame = GetSecs - startTime;
            end
        else
            Screen( 'DrawTexture', winPtr, Texture( 3 )); % current frame
            % Flip to the screen
            Screen('Flip', winPtr);
        end
        % check to see if the "esc" button was pressed
        breakIt = escPressed(keybs);
    end
    sca;
catch ME
    Screen('CloseAll');
    ListenChar;
    ShowCursor;
    rethrow(ME);
end
disp(['elapsedTime = ' num2str(elapsedTime)]);
ListenChar(1);
ShowCursor;
Screen('CloseAll');
save(outFile,'stim');