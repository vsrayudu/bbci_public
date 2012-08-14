function ht = misc_history(obj)
%MISC_HISTORY - Records the history of function calls related to 
%
%Synopsis:
%  MISC_HISTORY(OBJ)
%
%Arguments:
%  OBJ:     object, e.g. a struct with EEG data, montage, marker
%
%Returns:
%  HT:      history, an array of structs with the following fields:
% 
%  fcn:         function handle
%  fcn_params:  names of function parameters
%  signature:   function signature as in the m-file
%  date:        date the function was executed
%  
%
% Note: misc_history 

% Matthias Treder 2012

maxSize = 10*1000*1000;   % max byte size of arguments saved in history

if isfield(obj,'history')
  ht = obj.history;
  N = numel(ht)+1;
else
  ht = struct();  
  N = 1;
end

objname = inputname(1);  % Name of object in caller's workspace

% Get function name (of caller)
ST = dbstack('-completenames',1);
% ht(N).signature = [ST(1).name ''];
ht(N).fcn = eval(['@' ST(1).name]);

% Regular expression to match the function signature -> find argument names
code = (evalc(['type ' ST(1).name])); % get function code
expr = ['^\s*function s*\[*\s*(\w+|\s*)*\]*\s*=\s*' ST(1).name '\s*\((\w+|\s+|,)*\)'];
token = regexpi(code,expr,'tokens');
token = strrep(token{1}{end},' ','');  % remove whitespace
token = regexp(token,',','split');   % split according to comma's

ht(N).fcn_params = setdiff(token,'varargin');

% Get argument values for named arguments
for ii=1:numel(token)
    if ~strcmp(token{ii},'varargin') && ~strcmp(token{ii},objname)
        s=evalin('caller',['whos(''' token{ii} ''')']);  % Get size of variable
        if s.bytes > maxSize
           ht(N).(token{ii}) = sprintf('variable exceeds maximum size %d kb',maxSize/1000);
        else
           ht(N).(token{ii}) = evalin('caller',token{ii});
        end
    end
end

% Get optional arguments (varargin)
% if any(ismember(token,'varargin'))
  va = evalin('caller','varargin');
    for ii=1:numel(token)
    if ~strcmp(token{ii},'varargin') && ~strcmp(token{ii},objname)
        s=evalin('caller',['whos(''' token{ii} ''')']);  % Get size of variable
        if s.bytes > maxSize
           ht(N).(token{ii}) = sprintf('variable exceeds maximum size %d kb',maxSize/1000);
        else
           ht(N).(token{ii}) = evalin('caller',token{ii});
        end
    end
end

% Get variable names of parameters (if any)
nin = evalin('caller','nargin');
ht(N).var = cell(nin,1);

% names = evalin('caller','arrayfun(@inputname,1:nargin,''UniformOutput'',0)');
for ii=1:nin
  ht(N).var{ii} = evalin('caller',['inputname(' num2str(ii) ')']);
end

ht(N).date= datestr(now,0);