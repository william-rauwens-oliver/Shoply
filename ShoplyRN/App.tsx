import React from 'react';
import { StatusBar } from 'react-native';
import { ThemeProvider } from './src/theme/ThemeContext';
import { AppNavigator } from './src/navigation/AppNavigator';

function App(): React.JSX.Element {
  return (
    <ThemeProvider>
      <StatusBar barStyle="dark-content" />
      <AppNavigator />
    </ThemeProvider>
  );
}

export default App;
