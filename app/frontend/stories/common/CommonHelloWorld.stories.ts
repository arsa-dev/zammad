// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import CommonHelloWorld from '@common/components/common/CommonHelloWorld.vue'

export default {
  title: 'Common/HelloWorld',
  component: CommonHelloWorld,
}

// TODO: Figure out a way to import props definition for components here.
const Template: Story = (args) => ({
  components: { CommonHelloWorld },
  setup() {
    return { args }
  },
  template: '<CommonHelloWorld v-bind="args" />',
})

export const WithoutMessage = Template.bind({})
WithoutMessage.args = {
  show: true,
  msg: '',
}

export const WithMessage = Template.bind({})
WithMessage.args = {
  show: true,
  msg: 'Hello World!!',
}
