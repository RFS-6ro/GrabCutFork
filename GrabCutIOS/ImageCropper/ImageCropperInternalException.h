#pragma once
#include <string>

class ImageCropperInternalException
{
private:
    std::string m_error;

public:
    ImageCropperInternalException(std::string error) : m_error(error) { }

    const char* getError() { return m_error.c_str(); }
};
