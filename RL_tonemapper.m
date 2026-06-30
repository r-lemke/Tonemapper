function finalImage = RL_tonemapper()
% TONEMAPPER_EXAMPLE - GUI for visualizing a simple color-preserving tone mapping process.
%
% Loads an HDR EXR image, desaturates it, applies a combination of Reinhard and logarithmic 
% tone mapping (instead of a custom curve), then re-saturates. The GUI displays the image at four stages:
% 1. Normalized HDR input
% 2. Desaturated input
% 3. Tonemapped image (Reinhard and Logarithmic Mapping)
% 4. Final resaturated image
%
% A saturation slider is provided to dynamically update the effect.
%

    % Load HDR image and get max value
    rgbImageHDR = exrread('Testrender_v001_linear_rec709.exr');
    maxHDR = max(rgbImageHDR(:));

    % Create GUI figure
    fig = figure('Name','Tonemapper Example','NumberTitle','off','Position',[100 100 1100 900]);

    % Create subplot axes for each processing step (2x2 layout)
    ax1 = subplot(2,2,1);
    ax2 = subplot(2,2,2);
    ax3 = subplot(2,2,3);
    ax4 = subplot(2,2,4);

    % Label for saturation
    uicontrol('Style','text','String','Saturation:', ...
              'FontSize', 12, 'FontWeight', 'bold', ...
              'Position',[300 65 100 30], 'BackgroundColor', get(fig, 'Color'));

    % Label for Reinhard White
    uicontrol('Style','text','String','White:', ...
              'FontSize', 12, 'FontWeight', 'bold', ...
              'Position',[300 25 100 30], 'BackgroundColor', get(fig, 'Color'));

    % Display for saturation value (updates live)
    satText = uicontrol('Style','text','String','0.70', ...
                        'FontSize', 12, ...
                        'Position',[380 65 60 30], 'BackgroundColor', get(fig, 'Color'));

    % Display for Reinhard White value (updates live)
    reinhardText = uicontrol('Style','text','String','0.70', ...
                        'FontSize', 12, ...
                        'Position',[380 25 60 30], 'BackgroundColor', get(fig, 'Color'));

    % Slider for adjusting saturation
    satSlider = uicontrol('Style','slider','Min',0,'Max',1,'Value',0.5,...
        'Position',[450 70 400 20],...
        'SliderStep',[0.01 0.1],...
        'Callback',@updateImage);

    % Slider for adjusting Reinhard White
    reinhardSlider = uicontrol('Style','slider','Min',1,'Max',maxHDR,'Value',13,...
        'Position',[450 30 400 20],...
        'SliderStep',[0.01 0.1],...
        'Callback',@updateImage);

    % Initial rendering
    updateImage();

    % Process and update image display
    function updateImage(~,~)
        saturationFactor = satSlider.Value;
        satText.String = sprintf('%.2f', saturationFactor);

        reinhardFactor = reinhardSlider.Value;
        reinhardText.String = sprintf('%.2f',reinhardFactor);

        val = reinhardFactor;

        % Step 1: Normalize HDR to [0,1]
        img = remap(rgbImageHDR, [0 maxHDR], [0 1]);

        % Step 2: Desaturate image
        postSat = desaturate(img, saturationFactor);

        % Step 3: Tonemap (Reinhard + Log)
        outRemapCurve = remap(postSat, [0 1], [0 maxHDR]);
        reinhard = tonemapReinhard(outRemapCurve, val);
        curved = remap(reinhard, [0 maxHDR], [0 1]);

        % Step 4: Resaturate back to original chroma range
        reSat = resaturate(curved, saturationFactor);

        % Optionally return final remapped image
        % finalImage = remap(reSat, [0 1], [0 maxHDR]);

        % Remap each stage for display
        viewImg    = remap(img, [0 1], [0 maxHDR]);
        viewPost   = remap(postSat, [0 1], [0 maxHDR]);
        viewCurve  = remap(curved, [0 1], [0 maxHDR]);
        viewFinal  = remap(reSat, [0 1], [0 maxHDR]);

        % Display all four stages
        imshow(viewImg,   [0 maxHDR], 'Parent', ax1); title(ax1, '1. Input Image');
        imshow(viewPost,  [0 maxHDR], 'Parent', ax2); title(ax2, '2. Desaturated');
        imshow(viewCurve, [0 maxHDR], 'Parent', ax3); title(ax3, '3. Tonemapped');
        imshow(viewFinal, [0 maxHDR], 'Parent', ax4); title(ax4, '4. Final Output');
    end
end

% ------------------ Helper Functions ------------------

function y = remap(b, fromRange, toRange)
% REMAP - Linearly maps a value from one range to another.
    a = fromRange(1); c = fromRange(2);
    x = toRange(1);   z = toRange(2);
    y = (b - a) * (z - x) / (c - a) + x;
end

function desat_RGB = desaturate(rgbImage, satFactor)
% DESATURATE - Reduces saturation of an RGB image by a satuartion factor using HSV color space.
    hsv = rgb2hsv(rgbImage);
    hsv(:,:,2) = hsv(:,:,2) * satFactor;
    desat_RGB = hsv2rgb(hsv);
end

function resat_RGB = resaturate(rgbImage, satFactor)
% RESATURATE - Re-applies saturation after tone mapping using HSV.
    hsv = rgb2hsv(rgbImage);
    hsv(:,:,2) = hsv(:,:,2) / satFactor;
    resat_RGB = hsv2rgb(hsv);
end

function out = tonemapReinhard(img, val)
% TONEMAPREINHARD - Applies Reinhard tone mapping:
    out = img .* (1 + img ./ (val^2)) ./ (1 + img);
end
