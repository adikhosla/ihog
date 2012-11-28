% invertHOG(feat)
%
% This function recovers the natural image that may have generated the HOG
% feature 'feat'.

function im = invertHOG(feat),
global ihog_pd
if isempty(ihog_pd),
  ihog_pd = load('pd.mat');
end
im = invertHOGdo(feat, ihog_pd);


function im = invertHOGdo(feat, pd),

[ny, nx, ~] = size(feat);

% pad feat with 0s if not big enough
if size(feat,1) < pd.ny,
  x = padarray(x, [pd.ny - size(x,1) 0 0], 0, 'post');
end
if size(feat,2) < pd.nx,
  x = padarray(x, [0 pd.nx - size(x,2) 0], 0, 'post');
end

% extract every window 
windows = zeros(pd.ny*pd.nx*32, (ny-pd.ny+1)*(nx-pd.nx+1));
c = 1;
for i=1:size(feat,1) - pd.ny + 1,
  for j=1:size(feat,2) - pd.nx + 1,
    hog = feat(i:i+pd.ny-1, j:j+pd.nx-1, :);
    windows(:,c)  = hog(:);
    c = c + 1;
  end
end

% solve lasso problem
param.lambda = pd.lambda;
param.mode = 2;
a = full(mexLasso(single(windows), pd.dhog, param));
recon = pd.dgray * a;

% reconstruct
im      = zeros((size(feat,1)+2)*pd.sbin, (size(feat,2)+2)*pd.sbin);
weights = zeros((size(feat,1)+2)*pd.sbin, (size(feat,2)+2)*pd.sbin);
c = 1;
for i=1:size(feat,1) - pd.ny + 1,
  for j=1:size(feat,2) - pd.nx + 1,
    fil = fspecial('gaussian', [(pd.ny+2)*pd.sbin (pd.nx+2)*pd.sbin], 75);
    patch = reshape(recon(:, c), [(pd.ny+2)*pd.sbin (pd.nx+2)*pd.sbin]);
    patch = patch .* fil;

    iii = (i-1)*pd.sbin+1:(i-1)*pd.sbin+(pd.ny+2)*pd.sbin;
    jjj = (j-1)*pd.sbin+1:(j-1)*pd.sbin+(pd.nx+2)*pd.sbin;

    im(iii, jjj) = im(iii, jjj) + patch;
    weights(iii, jjj) = weights(iii, jjj) + 1;

    c = c + 1;
  end
end

% post processing averaging and clipping
im = im ./ weights;
im = im(1:(ny+2)*pd.sbin, 1:(nx+2)*pd.sbin);
im(:) = im(:) - min(im(:));
im(:) = im(:) / max(im(:));