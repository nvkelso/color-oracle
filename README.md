![image](http://colororacle.org/rw_common/images/icon48x48.png)

# Color Oracle

_Design for the Color Impaired_

**Go to [http://colororacle.org/](http://colororacle.org/) for downloads, usage, design tips, user manual, and links!**

**This repo contains the Mac version. Looking for the [JAVA versions for Windows, Linux](https://github.com/nvkelso/color-oracle-java)?**

Color Oracle is a free color blindness simulator for Window, Mac and Linux. It takes the guesswork out of designing for color blindness by showing you in real time what people with common color vision impairments will see.

Color Oracle applies a full screen color filter to art you are designing – independently of the software in use. Eight percent of all males are affected by color vision impairment – make sure that your graphical work is readable by the widest possible audience.

Read this article for more information: [Color Design for the Color Vision Impaired](http://colororacle.org/design.html)

## Authors

* Programming of the first version: [Bernie Jenny](http://berniejenny.info).
* Ideas, testing and icon: [Nathaniel Vaughn Kelso](https://en.wikipedia.org/wiki/Nathaniel_Vaughn_Kelso).

## Feedback
Color Oracle is a work in progress and will improve with time and your input. Please share your Color Oracle testimonial with us and send us an [email](mailto:nvkelso@gmail.com).

## Note
Color Oracle is using the best available algorithm for simulating color vision impairment. However, highly saturated color may not simulate well using the present version of Color Oracle.

## Downloads

Download the latest version for macOS, Windows and Linux from http://colororacle.org/.

## Development ##
### Requirements

If you wish to build it yourself, you will need the following components/tools:

* a recent Xcode
* Git

### TeamID

Yes. This is a wall of text, but it’s a pretty simple solution for an annoying problem.

The project is configured to code sign the app. For code signing, you need a valid Apple Developer code signing certificate in your keychain, and you need to specify your Apple Developer Program TeamID in the build settings of an Xcode project. The former should be covered by adding your developer account to Xcode Preferences > Accounts > Apple ID.

To add the TeamID to the project, create a new file `DEVELOPMENT_TEAM.xcconfig` in the `Xcode-config` folder of your working copy and add the following build setting to the file:

```
DEVELOPMENT_TEAM = [Your TeamID]
```

The `DEVELOPMENT_TEAM.xcconfig` file should not be added to any git commit. The `.gitignore` file will prevent it from getting committed to the repository. 

See the file `Xcode-config/Shared.xcconfig` for a more detailed explanation of how to set this up for this or for your own projects. 

A big thank-you goes to [Jeff Johnson](https://github.com/lapcat/Bonjeff) who has come up with this way of handling the `DEVELOPMENT_TEAM` issue for open-source projects. 

Without the above solution, every developer would have to change the `DEVELOPMENT_TEAM` for themselves and keep the change from getting into version control. Otherwise, every other developer would get conflicts and non-working builds. 


You can then open the Xcode project file and build.

## License

CC-BY using the [MIT License](http://opensource.org/licenses/MIT), see the LICENSE.txt file for complete details.

© 2006–2018 by Bernhard Jenny and Nathaniel V. Kelso.
