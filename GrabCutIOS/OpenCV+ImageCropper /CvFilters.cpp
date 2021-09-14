#include "CvFilters.h"
#include "ImageCropperInternalException.h"

cv::Mat CvFilters::makeTransparent(cv::Mat img)
{
    try
    {
        cv::Mat transparentImg(img.rows, img.cols, CV_8UC4);

        cv::cvtColor(img, transparentImg, cv::COLOR_BGR2BGRA);

        uint8_t* transparentImgPtr = (uint8_t*)transparentImg.data;

        for (int i = 0; i < transparentImg.rows; i++)
        {
            for (int j = 0; j < transparentImg.cols; j++)
            {
                uint32_t index = i * transparentImg.cols * 4 + j * 4;
                uint8_t transparentImgIntensityb = transparentImgPtr[index + 0]; // b
                uint8_t transparentImgIntensityg = transparentImgPtr[index + 1]; // g
                uint8_t transparentImgIntensityr = transparentImgPtr[index + 2]; // r

                if (transparentImgIntensityb <= (uint8_t)10 &&
                    transparentImgIntensityg <= (uint8_t)10 &&
                    transparentImgIntensityr <= (uint8_t)10)
                {
                    transparentImgPtr[index + 3] = (uint8_t)0;
                }
                else
                {
                    transparentImgPtr[index + 3] = (uint8_t)255;
                }
            }
        }

        return transparentImg;
    }
    catch (const std::exception&)
    {
        throw ImageCropperInternalException("transparent went wrong");
    }
}

void CvFilters::applyGrabCut(cv::Mat* img, cv::Rect rect, cv::Mat* mask)
{
    try
    {
        cv::Mat maskedRect = cv::Mat(img->rows, img->cols, CV_8UC1);
        cv::Mat bgr(1, 65, CV_64F);
        cv::Mat fgr(1, 65, CV_64F);

        grabCut(*img, maskedRect, rect, bgr, fgr, 5, cv::GC_INIT_WITH_RECT);


        if (mask != nullptr)
        {
            uint8_t* maskRectPtr = (uint8_t*)maskedRect.data;
            uint8_t* maskPtr = (uint8_t*)mask->data;

            for (int i = 0; i < mask->rows; i++)
            {
                for (int j = 0; j < mask->cols; j++)
                {
                    uint8_t maskIntensity = maskPtr[i * mask->cols + j];

                    if (maskIntensity > (uint8_t)200)
                    {
                        maskRectPtr[i * mask->cols + j + 0] = (uint8_t)1;
                    }
                    else if (maskIntensity < (uint8_t)50)
                    {
                        maskRectPtr[i * mask->cols + j + 0] = (uint8_t)0;
                    }
                }
            }

            grabCut(*img, maskedRect, rect, bgr, fgr, 5, cv::GC_EVAL);

            for (int i = 0; i < maskedRect.rows; i++)
            {
                for (int j = 0; j < maskedRect.cols; j++)
                {
                    uint8_t maskRectIntensity = maskRectPtr[i * maskedRect.cols + j]; // Gray

                    if (maskRectIntensity == (uint8_t)1 || maskRectIntensity == (uint8_t)3)
                    {
                        maskRectPtr[i * maskedRect.cols + j + 0] = (uint8_t)1;
                    }
                    else
                    {
                        maskRectPtr[i * maskedRect.cols + j + 0] = (uint8_t)0;
                    }
                }
            }
        }

        cropContours(&maskedRect);
        cv::Mat imgCopy = img->clone();
        cv::Mat maskedBgr(img->rows, img->cols, CV_8UC3);
        cv::cvtColor(maskedRect, maskedBgr, cv::COLOR_GRAY2BGR);
        cv::multiply(imgCopy, maskedBgr, *img);

        cv::Mat mat = makeTransparent(*img);
        mat.copyTo(*img);
    }
    catch (const std::exception&)
    {
        throw ImageCropperInternalException("grab cut went wrong");
    }
}

void CvFilters::cropContours(cv::Mat * img)
{
    try
    {
        cv::threshold(*img, *img, 1, 255, 0);
        cv::medianBlur(*img, *img, 5);
        cv::threshold(*img, *img, 225, 255, 0);
    }
    catch (const std::exception&)
    {
        throw ImageCropperInternalException("resizing contours went wrong");
    }
}
