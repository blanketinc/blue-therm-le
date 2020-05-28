
# react-native-blue-therm-le

## Getting started

`$ npm install react-native-blue-therm-le --save`

### Mostly automatic installation

`$ react-native link react-native-blue-therm-le`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-blue-therm-le` and add `RNBlueThermLe.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNBlueThermLe.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNBlueThermLePackage;` to the imports at the top of the file
  - Add `new RNBlueThermLePackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-blue-therm-le'
  	project(':react-native-blue-therm-le').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-blue-therm-le/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-blue-therm-le')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNBlueThermLe.sln` in `node_modules/react-native-blue-therm-le/windows/RNBlueThermLe.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Blue.Therm.Le.RNBlueThermLe;` to the usings at the top of the file
  - Add `new RNBlueThermLePackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNBlueThermLe from 'react-native-blue-therm-le';

// TODO: What to do with the module?
RNBlueThermLe;
```
  