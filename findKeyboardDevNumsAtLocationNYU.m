function devNum = findKeyboardDevNumsAtLocationNYU(location)% find the device numbers for the keyboard and the for the keypad...% 11/17/07 DE% 31-March-2011 Rachel Denison%% Updated to take location argument% 2012 September 1%% Updated for NYU% 2014 Feb 12devices = PsychHID('Devices');devNum = [];for devicecounter = 1:length(devices)    switch location        case {'CarrascoL1'}            if (strcmp(devices(devicecounter).product, 'Apple Keyboard') == 1) && (devices(devicecounter).productID == 544)                devNum = devicecounter;            elseif (strcmp(devices(devicecounter).product, 'Apple Extended USB Keyboard') == 1) && (devices(devicecounter).productID == 523)                devNum = devicecounter;            end        case 'laptop'            if (strcmp(devices(devicecounter).product, 'Apple Internal Keyboard / Trackpad') == 1) && (strcmp(devices(devicecounter).usageName, 'Keyboard') == 1)                devNum = devicecounter;            end        case 'desk'            if (strcmp(devices(devicecounter).product, 'Apple Keyboard') == 1) && (strcmp(devices(devicecounter).usageName, 'Keyboard') == 1)                devNum = devicecounter;            end        otherwise            error('Testing location not found by findKeyboardDevNumsAtLocationNYU.')    endend