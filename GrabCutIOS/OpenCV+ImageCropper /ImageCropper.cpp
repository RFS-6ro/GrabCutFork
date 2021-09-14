#include "ImageCropper.h"
#include "CvFilters.h"
#include "ImageCropperArgumentException.h"

ImageCropper::ImageCropper()
{
    pxlHeight = -1;
    pxlWidth = -1;
}

ImageCropper::ImageCropper(cv::Mat sourceData)
{
    setSourceImage(sourceData);
}

void ImageCropper::setSourceImage(cv::Mat sourceData)
{
    pxlHeight = sourceData.rows;
    pxlWidth = sourceData.cols;
    srcImg = sourceData.clone();
}


void ImageCropper::setMask(cv::Mat maskData)
{
    if (maskData.empty())
    {
        mask = cv::Mat();
        return;
    }

    if (srcImg.empty())
    {
        throw ImageCropperArgumentException("Image is not assigned");
    }

    if (maskData.cols != pxlWidth ||
        maskData.rows != pxlHeight)
    {
        throw ImageCropperArgumentException("Mask does not fit source image");
    }

    if (maskData.channels() != 1)
    {
        throw ImageCropperArgumentException("Mask should contains only one gray channel");
    }

    mask = maskData.clone();
}

void ImageCropper::setMask(int32_t * white,
                           int32_t whiteLength,
                           int32_t * black,
                           int32_t blackLength)
{
    if (white == nullptr)
    {
        throw ImageCropperArgumentException("ArgumentNullException white");
    }

    if (black == nullptr)
    {
        throw ImageCropperArgumentException("ArgumentNullException black");
    }

    if (srcImg.empty())
    {
        throw ImageCropperArgumentException("Image is not assigned");
    }

    if (whiteLength % 2 == 1 || blackLength % 2 == 1)
    {
        throw ImageCropperArgumentException("Arrays are containing not only points");
    }

    mask = cv::Mat(srcImg.cols, srcImg.rows, CV_8UC1, cv::Scalar(125));

    uint8_t* data = (uint8_t*)mask.data;

    for (int i = 0; i < whiteLength; i += 2)
    {
        data[white[i] * mask.cols + white[i + 1] + 0] = (uint8_t)255;
    }

    for (int i = 0; i < blackLength; i += 2)
    {
        data[black[i] * mask.cols + black[i + 1] + 0] = (uint8_t)0;
    }
}

void ImageCropper::setRectangle(int32_t x1,
                                int32_t y1,
                                int32_t x2,
                                int32_t y2)
{
    if (srcImg.empty())
    {
        throw ImageCropperArgumentException("Image is not assigned");
    }

    if (x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0)
    {
        throw ImageCropperArgumentException("Coords should be greater or equal zero");
    }

    int32_t RectanglePointX = std::min(x1, x2);
    int32_t RectanglePointY = std::min(y1, y2);
    int32_t RectangleWidth = std::abs(x2 - x1);
    int32_t RectangleHeight = std::abs(y2 - y1);

    if (RectanglePointX + RectangleWidth > srcImg.cols ||
        RectanglePointY + RectangleHeight > srcImg.rows)
    {
        throw ImageCropperArgumentException("Rect is out of image's bounds");
    }

    rect = cv::Rect(RectanglePointX, RectanglePointY, RectangleWidth, RectangleHeight);
}

void ImageCropper::setRectangle(cv::Rect rect)
{
    setRectangle(rect.x, rect.y, rect.x + rect.width, rect.y + rect.height);
}

cv::Mat ImageCropper::getCroppedMat()
{
    if (srcImg.empty())
    {
        throw ImageCropperArgumentException("Image is not assigned");
    }

    try
    {
        CvFilters::applyGrabCut(&srcImg, rect, &mask);
        return srcImg;
    }
    catch (const std::exception&)
    {
        throw;
    }
}
