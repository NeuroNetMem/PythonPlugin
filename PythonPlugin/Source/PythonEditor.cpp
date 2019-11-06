/*
 ------------------------------------------------------------------
 
 Python Plugin
 Copyright (C) 2016 FP Battaglia
 
 based on
 Open Ephys GUI
 Copyright (C) 2013, 2015 Open Ephys
 
 ------------------------------------------------------------------
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */
/*
  ==============================================================================

    PythonEditor.cpp
    Created: 13 Jun 2014 4:21:01pm
    Author:  fpbatta

  ==============================================================================
*/

#include "PythonPlugin.h"
#include "PythonEditor.h"

#include <stdio.h>

PythonEditor::PythonEditor(GenericProcessor* parentNode, bool useDefaultParameterEditors=true)
    : GenericEditor(parentNode, useDefaultParameterEditors)

{

    pythonPlugin = (PythonPlugin*) parentNode;

    lastFilePath = File::getCurrentWorkingDirectory();

    font = Font("Small Text", 13, Font::plain);
    fileButton = new UtilityButton("Select file", font);
    fileButton->addListener(this);
    fileButton->setBounds(30,50,120,25);
    addAndMakeVisible(fileButton);

    fileNameLabel = new Label("FileNameLabel", "No file selected.");
    fileNameLabel->setBounds(20,80,140,25);
    addAndMakeVisible(fileNameLabel);

    desiredWidth = 180;

    setEnabledState(false);

}

PythonEditor::~PythonEditor()
{
    for(int i=0; i < parameterInterfaces.size(); i++)
    {
        removeChildComponent(parameterInterfaces[i]);
    }
    //deleteAllChildren();
}

void PythonEditor::setFile(String file)
{

    File fileToRead(file);
    lastFilePath = fileToRead.getParentDirectory();
    pythonPlugin->setFile(fileToRead.getFullPathName());
   
    fileNameLabel->setText(fileToRead.getFileName(), dontSendNotification);

    setEnabledState(true);
    removeChildComponent(fileButton);
    removeChildComponent(fileNameLabel);
    
    repaint();
}

Component *PythonEditor::addToggleButton(String paramName, bool isEnabled)
{
    PythonParameterButtonInterface *ppbi = new PythonParameterButtonInterface(paramName, isEnabled, (PythonPlugin *)getProcessor());
    parameterInterfaces.add(ppbi);
    int i = parameterInterfaces.size();
    ppbi->setBounds(10, 22 * i, 100 ,21);
    addAndMakeVisible(ppbi);
    std::cout << "Created button " << i << std::endl;
    return ppbi;

}

Component *PythonEditor::addComboBox(String paramName, int nEntries, int *entries)
{
    PythonParameterComboBoxInterface *ppcbi = new PythonParameterComboBoxInterface(paramName, nEntries, entries, (PythonPlugin *)getProcessor());
    parameterInterfaces.add(ppcbi);
    int i = parameterInterfaces.size();
    ppcbi->setBounds(10, 22 * i, 100 ,21);
    addAndMakeVisible(ppcbi);
    std::cout << "Created combobox " << i << std::endl;
    return ppcbi;
}

Component *PythonEditor::addSlider(String paramName, float rangeMin, float rangeMax, float startValue)
{
    PythonParameterSliderInterface *ppsi = new PythonParameterSliderInterface(paramName, (double)rangeMin, (double)rangeMax, (double)startValue, (PythonPlugin *)getProcessor());
    parameterInterfaces.add(ppsi);
    int i = parameterInterfaces.size();
    ppsi->setBounds(10, 22 * i, 150 ,21);
    addAndMakeVisible(ppsi);
    std::cout << "Created slider " << i << std::endl;
    return ppsi;
}

void PythonEditor::buttonEvent(Button* button)
{

    if (!acquisitionIsActive)
    {

        if (button == fileButton)
        {
            //std::cout << "Button clicked." << std::endl;
            FileChooser choosePythonFile("Please select the file you want to load...",
                                             lastFilePath,
                                             "*");

            if (choosePythonFile.browseForFileToOpen())
            {
                // Use the selected file
                setFile(choosePythonFile.getResult().getFullPathName());
            }
        }

    }
}

void PythonEditor::channelChanged(int chan, bool newState)
{
    pythonPlugin->channelChanged(chan, newState);
}

void PythonEditor::saveCustomParameters(XmlElement* xml)
{

    xml->setAttribute("Type","PythonPlugin");
    XmlElement* childNode = xml->createNewChildElement("PYTHONPLUGIN");
    childNode->setAttribute("path", pythonPlugin->getFile());
    ParamConfig *params = pythonPlugin->getPythonParams();
    
    for(int i = 0; i < pythonPlugin->getNumPythonParams(); i++)
    {
        char *name = params[i].name;
        if(params[i].type == INT_SET || params[i].type == TOGGLE)
        {
            int value = pythonPlugin->getIntPythonParameter(String(name));
            childNode->setAttribute(name, value);
        }
        else
        {
            float value = pythonPlugin->getFloatPythonParameter(String(name));
            childNode->setAttribute(name, value);

        }
    }

}

void PythonEditor::loadCustomParameters(XmlElement* xml)
{

    forEachXmlChildElement(*xml, element)
    {
        if (element->hasTagName("PYTHONPLUGIN"))
        {
            String filepath = element->getStringAttribute("path");
            setFile(filepath);
            ParamConfig *params = pythonPlugin->getPythonParams();
            Component **controls = pythonPlugin->getParamsControl();

            for(int i = 0; i < pythonPlugin->getNumPythonParams(); i++)
                {
                    if(element->hasAttribute(String(params[i].name)))
                       {
                           if(params[i].type == INT_SET || params[i].type == TOGGLE)
                           {
                               int value = element->getIntAttribute(String(params[i].name));
                               pythonPlugin->setIntPythonParameter(String(params[i].name), value);
                               if(params[i].type == INT_SET)
                               {
                                   // it's a combo box
                                   PythonParameterComboBoxInterface *pcbi =  dynamic_cast<PythonParameterComboBoxInterface *>(controls[i]);
                                   pcbi->setEntryFromValue(value);
                               }
                               else
                               {
                                   // it's a toggle button
                                   PythonParameterButtonInterface *pbi = dynamic_cast<PythonParameterButtonInterface *>(controls[i]);
                                   pbi->setToggleStateFromValue(value);
                               }
                           }
                           else
                           {
                               float value = element->getDoubleAttribute(String(params[i].name));
                               pythonPlugin->setFloatPythonParameter(String(params[i].name), value);
                               // it's a slider
                               PythonParameterSliderInterface *psi = dynamic_cast<PythonParameterSliderInterface *>(controls[i]);
                               psi->setSliderFromValue(value);

                           }
                       }
                }
        }
    }
}

                       
                       
PythonParameterButtonInterface::PythonParameterButtonInterface(String paramName_, int defaultVal, PythonPlugin *plugin_)
:  paramName(paramName_), isEnabled(defaultVal), plugin(plugin_)
{
    std::cout << "creating a button with name " << paramName << std::endl;
    theButton = new ToggleButton(paramName);
    theButton->setToggleState(isEnabled, dontSendNotification);
    theButton->addListener(this);
    //    triggerButton->setRadius(3.0f);
    theButton->setBounds(1,1,55,20);
    addAndMakeVisible(theButton);
   font = Font("Small Text", 10, Font::plain);
    
}

PythonParameterButtonInterface::~PythonParameterButtonInterface()
{
    
}

void PythonParameterButtonInterface::paint(Graphics& g)
{
    g.setColour(Colours::lightgrey);
    
    g.fillRoundedRectangle(0,0,getWidth(),getHeight(),4.0f);
    
    if (isEnabled)
        g.setColour(Colours::black);
    else
        g.setColour(Colours::grey);
    
    
    g.setFont(font);
    
}

void PythonParameterButtonInterface::buttonClicked(Button* button)
{
    // delegate to processor
    plugin->setIntPythonParameter(paramName, theButton->getToggleState());
}

void PythonParameterButtonInterface::setToggleStateFromValue(int value)
{
    theButton->setToggleState((bool)value, dontSendNotification);
}

PythonParameterComboBoxInterface::PythonParameterComboBoxInterface(String paramName_, int nEntries_, int *entries_, PythonPlugin *plugin_)
:  paramName(paramName_), nEntries(nEntries_), entries(entries_),  plugin(plugin_)
{
    std::cout << "creating a combobox with name " << paramName << std::endl;
    
    theComboBox = new ComboBox();
    theComboBox->setBounds(1, 1, 80, 20);
    theComboBox->addListener(this);
    theComboBox->addItem(paramName, 1);
 
    for(int i = 0; i < nEntries; i++)
    {
        theComboBox->addItem(String(entries[i]), i+2);
    }
    
    theComboBox->setSelectedId(1);
    addAndMakeVisible(theComboBox);
    font = Font("Small Text", 10, Font::plain);
    
}

PythonParameterComboBoxInterface::~PythonParameterComboBoxInterface()
{
}

void PythonParameterComboBoxInterface::paint(Graphics& g)
{
    g.setColour(Colours::lightgrey);
    
    g.fillRoundedRectangle(0,0,getWidth(),getHeight(),4.0f);
    
    if (isEnabled)
        g.setColour(Colours::black);
    else
        g.setColour(Colours::grey);
    
    
    g.setFont(font);
    
    
}

void PythonParameterComboBoxInterface::comboBoxChanged(ComboBox* comboBox)
{
    int resp;
    
    resp = comboBox->getSelectedId();
    if (resp > 1) {
        // delegate to processor
        plugin->setIntPythonParameter(paramName, entries[resp-2]);
        std::cout << paramName << ": changed to " << String(entries[resp-2]) << std::endl;
    }
}

void PythonParameterComboBoxInterface::setEntryFromValue(int value)
{
    int id;
    for (int i = 0; i < nEntries; i++)
    {
        if(entries[i]==value)
        {
            id = i+2;
            break;
        }
            
    }
    theComboBox->setSelectedId(id);
}

PythonParameterSliderInterface::PythonParameterSliderInterface(String paramName_, double rangeMin, double rangeMax, double startValue, PythonPlugin *plugin_)
:  paramName(paramName_),  plugin(plugin_)
{
    std::cout << "creating a slider with name " << paramName << std::endl;
    
    
    //fileNameLabel = new Label("FileNameLabel", "No file selected.");
    titleLabel = new Label("Title label", paramName);
    titleLabel->setBounds(1, 1, 40, 20);
    addAndMakeVisible(titleLabel);
    theSlider = new Slider(paramName);
    theSlider->setBounds(41, 1, 110, 20);
    theSlider->setTextBoxStyle(Slider::TextBoxLeft, false, 40, 20);
    theSlider->setRange(rangeMin, rangeMax);
    theSlider->addListener(this);
    theSlider->setValue(startValue);
    addAndMakeVisible(theSlider);
    font =  Font("Small Text", 10, Font::plain);

    
}

PythonParameterSliderInterface::~PythonParameterSliderInterface()
{
}

void PythonParameterSliderInterface::paint(Graphics& g)
{
    g.setColour(Colours::lightgrey);
    
    g.fillRoundedRectangle(0,0,getWidth(),getHeight(),4.0f);
    
    if (isEnabled)
        g.setColour(Colours::black);
    else
        g.setColour(Colours::grey);
    
    g.setFont(font);
    
  
}

void PythonParameterSliderInterface::sliderValueChanged(Slider *slider)
{
    double resp;
    
    resp = slider->getValue();
    // delegate to processor
    plugin->setFloatPythonParameter(paramName, (float)resp);
    std::cout << paramName << ": changed to " << resp << std::endl;
}

void PythonParameterSliderInterface::setSliderFromValue(float value)
{
    theSlider->setValue((double)value);
}





